use crate::hatestack::Hatestack;
use crate::jetstream::ProcessedPost;
use futures_util::{SinkExt, StreamExt};
use std::net::IpAddr;
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::net::TcpStream;
use tokio::sync::Mutex;
use tokio::sync::broadcast::Receiver;
use tokio::time::timeout;
use tokio_tungstenite::WebSocketStream;
use tokio_tungstenite::tungstenite::Message;
use tracing::{Instrument, debug, error, error_span, warn};

type ClientStream = WebSocketStream<TcpStream>;

#[derive(Debug, Clone)]
struct HandshakeError {}

enum FeedMode {
    Interval,
    Threshold,
}

pub struct Client {
    stack: Arc<Mutex<Hatestack>>,
    feed_mode: FeedMode,
    interval: Duration,
    threshold: f64,
}

impl Client {
    pub fn new() -> Self {
        Self::new_with_stack(Hatestack::new())
    }

    pub fn new_with_stack(stack: Hatestack) -> Self {
        Self {
            stack: Arc::new(Mutex::new(stack)),
            feed_mode: FeedMode::Threshold,
            threshold: 0.0,
            interval: Duration::from_secs(1),
        }
    }

    pub fn _handle_interval_cmd(&mut self, segments: &Vec<&str>) {
        match segments.get(1) {
            Some(x) => match u32::from_str(x) {
                Ok(v) => {
                    self.interval = Duration::from_millis(v as u64);
                }
                Err(_) => {
                    error!("Failed to parse INTERVAL of {}", x);
                }
            },
            _ => {
                error!("Expected a parameter for INTERVAL command");
            }
        }
    }

    pub fn _handle_threshold_cmd(&mut self, segments: &Vec<&str>) {
        match segments.get(1) {
            Some(x) => match f64::from_str(x) {
                Ok(v) => {
                    self.threshold = v;
                }
                Err(_) => {
                    error!("Failed to parse THRESHOLD of {}", x);
                }
            },
            _ => {
                error!("Expected a parameter for THRESHOLD command");
            }
        }
    }

    pub fn handle_client_command(&mut self, raw: &str) {
        let segments: Vec<&str> = raw.split_whitespace().collect();
        let command = match segments.get(0) {
            Some(v) => *v,
            None => return,
        };

        if command == "MODE" {
            match segments.get(1) {
                Some(&"RATE") => self.feed_mode = FeedMode::Interval,
                Some(&"THRESHOLD") => self.feed_mode = FeedMode::Threshold,
                Some(x) => error!("Unknown MODE argument: {}", x),
                None => error!("Missing MODE argument"),
            }
        } else if command == "INTERVAL" {
            self._handle_interval_cmd(&segments);
        } else if command == "THRESHOLD" {
            self._handle_threshold_cmd(&segments);
        }
    }

    pub async fn client_loop(
        &mut self,
        mut ws: ClientStream,
        recv: Receiver<ProcessedPost>,
        client_id: usize,
        client_addr: IpAddr,
    ) {
        let client_addr_string = client_addr.to_string();
        let span = error_span!("handle_client", client_id, client_addr = client_addr_string);

        async move {
            let mut r = recv;

            match self.handshake(&mut ws).await {
                Ok(_) => {
                    debug!("Client handshake succeeded");
                }
                Err(_) => {
                    error!("Client handshake failed");
                    return;
                }
            }

            let (mut sock_tx, mut sock_rx) = ws.split();

            let mut last_send: Option<Instant> = None;

            loop {
                match timeout(Duration::from_millis(50), r.recv()).await {
                    Ok(Ok(v)) => self.stack.lock().await.add(v),
                    Ok(Err(_)) => {
                        error!("Could not receive a processed post");
                        return;
                    }
                    Err(_) => {}
                };

                match timeout(Duration::from_millis(50), sock_rx.next()).await {
                    Ok(Some(Ok(v))) => {
                        if let Ok(t) = v.to_text() {
                            self.handle_client_command(t);
                        }
                        // Do nothing if it can't be parsed
                    }
                    Ok(Some(Err(_))) => {
                        error!("Failed receiving a message from the client");
                        return;
                    }
                    Ok(None) => {
                        // Did not time out; no messages
                    }
                    Err(_) => {
                        // Timeout case
                    }
                };

                let mut message: Option<ProcessedPost> = None;
                if matches!(self.feed_mode, FeedMode::Interval) {
                    // Send something right away if this is our first loop.
                    // We want the client to get a message ASAP.
                    if last_send.is_none()
                        || last_send.get_or_insert(Instant::now()).elapsed() > self.interval
                    {
                        message = self.stack.lock().await.pop();
                        if message.is_none() {
                            warn!("Feed empty in interval mode");
                        }
                    }
                } else if matches!(self.feed_mode, FeedMode::Threshold) {
                    if let Some(p) = self.stack.lock().await.le_threshold(self.threshold) {
                        message = Some(p);
                        // Minimum 100ms send interval in threshold mode
                        tokio::time::sleep(Duration::from_millis(100)).await;
                    } else {
                        // This is a common case
                    }
                }

                if message.is_none() {
                    // We may not have successfully retrieved a message, regardless of feed mode. Skip.
                    continue;
                }

                let sr = match serde_json::to_string(&message) {
                    Ok(v) => v,
                    Err(_) => {
                        error!("Failed to serialize a processed post");
                        return;
                    }
                };

                match sock_tx.send(Message::text(sr)).await {
                    Ok(_) => {
                        last_send = Some(Instant::now());
                    }
                    Err(_) => {
                        error!("Couldn't send to socket - disconnecting");
                        return;
                    }
                };
            }
        }
        .instrument(span)
        .await;
    }

    async fn handshake(&self, wss: &mut ClientStream) -> Result<(), HandshakeError> {
        let raw = wss.next().await;
        let s1 = match raw {
            Some(Ok(m)) => {
                // We are connected
                match m.to_text() {
                    Ok(v) => v.to_string(),
                    Err(_) => return Err(HandshakeError {}),
                }
            }
            _ => {
                // Client disconnected;
                return Err(HandshakeError {});
            }
        };

        match HandshakeMessages::from_str(s1.as_str()) {
            Some(HandshakeMessages::ClientReady) => {
                wss.send(Message::from(HandshakeMessages::ServerReply.as_str()))
                    .await
                    .unwrap();
                Ok(())
            }
            _ => Err(HandshakeError {}),
        }
    }
}

enum HandshakeMessages {
    ClientReady,
    ServerReply,
}

impl HandshakeMessages {
    fn from_str(s: &str) -> Option<HandshakeMessages> {
        match s {
            "READY" => Some(HandshakeMessages::ClientReady),
            "OKAYLESGO" => Some(HandshakeMessages::ServerReply),
            _ => None,
        }
    }
    fn as_str(&self) -> &'static str {
        match self {
            HandshakeMessages::ClientReady => "READY",
            HandshakeMessages::ServerReply => "OKAYLESGO",
        }
    }
}
