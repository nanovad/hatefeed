mod client;
mod hatestack;
mod jetstream;

use crate::client::Client;
use crate::hatestack::Hatestack;
use crate::jetstream::ProcessedPost;
use crate::jetstream::jetstream::Jetstream;
use std::collections::VecDeque;
use std::net::{IpAddr, SocketAddr};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, OnceLock};
use tokio::net::TcpStream;
use tokio::sync::broadcast::Receiver;
use tokio::sync::{Mutex, broadcast};
use tokio_tungstenite::tungstenite::handshake::server::{ErrorResponse, Request, Response};
use tokio_tungstenite::tungstenite::http::{HeaderName, HeaderValue};
use tracing::{Level, error, info, warn};

#[derive(Clone)]
struct WebserverState {
    pp_sender: broadcast::Sender<ProcessedPost>,
}

#[derive(Debug)]
struct TailQueue {
    items: VecDeque<ProcessedPost>,
    limit: usize,
}

impl TailQueue {
    pub fn new(limit: usize) -> TailQueue {
        TailQueue {
            items: VecDeque::with_capacity(limit),
            limit,
        }
    }

    pub fn push_overwrite(&mut self, val: &ProcessedPost) {
        if self.items.len() == self.limit {
            self.items.pop_front();
        }
        self.items.push_back(val.to_owned());
    }
}

static CLIENT_COUNTER: OnceLock<Arc<AtomicUsize>> = OnceLock::new();
// A copy of the last 128 posts received that can be cloned to clients to prime them with data when they connect.
static TAIL_QUEUE: OnceLock<Mutex<TailQueue>> = OnceLock::new();
const TAIL_QUEUE_SIZE: usize = 128;

#[tokio::main]
async fn main() {
    let tracing_sub = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(Level::DEBUG)
        .finish();
    tracing::subscriber::set_global_default(tracing_sub).expect("Setting tracing default failed");
    info!("Hatefeed daemon v{} startup", env!("CARGO_PKG_VERSION"));

    TAIL_QUEUE
        .set(Mutex::new(TailQueue::new(TAIL_QUEUE_SIZE)))
        .expect("Failed to initialize TAIL_QUEUE");

    let (js_tx, _) = broadcast::channel(100);
    let j = Jetstream::connect(&js_tx)
        .await
        .expect("Failed to connect to Jetstream");
    let get_loop = tokio::spawn(j.reconnect_loop());
    info!("Connected to Jetstream");

    let tail_queue_loop = tokio::spawn(collect_tail_queue(js_tx.subscribe()));

    let state = WebserverState { pp_sender: js_tx };

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080")
        .await
        .expect("Failed to bind listener");
    info!(
        "Listening on: {}",
        listener
            .local_addr()
            .expect("Could not determine local address")
    );

    while let Ok((stream, addr)) = listener.accept().await {
        tokio::spawn(handler(state.clone(), stream, addr));
    }
    get_loop.abort();
    tail_queue_loop.abort();
    info!("Shutdown complete");
}

pub fn next_client_id() -> usize {
    CLIENT_COUNTER
        .get_or_init(|| Arc::new(AtomicUsize::new(0)))
        .fetch_add(1, Ordering::Relaxed)
}

async fn collect_tail_queue(mut rx: Receiver<ProcessedPost>) {
    loop {
        let pp = match rx.recv().await {
            Ok(v) => v,
            Err(_) => panic!("Tail queue collection failed"),
        };
        let mut gs_temp = TAIL_QUEUE
            .get()
            .expect("TAIL_QUEUE uninitialized")
            .lock()
            .await;
        gs_temp.push_overwrite(&pp);
    }
}

async fn handler(state: WebserverState, raw_stream: TcpStream, addr: SocketAddr) {
    let client_id = next_client_id();
    let mut client_ip: IpAddr = addr.ip();
    let header_log_callback =
        |request: &Request, response: Response| -> Result<Response, ErrorResponse> {
            let mut forwarded_for: Option<&str> = None;
            for header in request.headers().iter() {
                let (name, value): (&HeaderName, &HeaderValue) = header;
                if name == "X-Forwarded-For" {
                    if let Ok(value_str) = value.to_str() {
                        forwarded_for = Some(value_str);
                    }
                }
            }
            if let Some(ff) = forwarded_for {
                info!("Handling WS connection from X-Forwarded-For: {}", ff);
                match ff.parse() {
                    Ok(v) => {
                        client_ip = v;
                    }
                    Err(_) => {
                        warn!("Could not parse X-Forwarded-Value into a SocketAddr");
                    }
                }
            } else {
                info!("Handling WS connection from {}", addr);
            }
            Ok(response)
        };
    let ws_stream = match tokio_tungstenite::accept_hdr_async(raw_stream, header_log_callback).await
    {
        Ok(v) => v,
        Err(_) => return,
    };
    let recv = state.pp_sender.subscribe();
    // Clone the TAIL_QUEUE if we can get it, otherwise set up a new client with a fresh, empty Hatestack.
    let mut c = match TAIL_QUEUE.get() {
        Some(v) => Client::new_with_stack(Hatestack::new_preloaded(
            v.lock().await.items.make_contiguous().into(),
        )),
        None => {
            error!("Couldn't get a lock on the TAIL_QUEUE, proceeding with empty");
            Client::new()
        }
    };
    c.client_loop(ws_stream, recv, client_id, client_ip).await;
}
