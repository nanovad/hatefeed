use std::time::Duration;

use crate::jetstream::{Message, ProcessedPost};
use futures_util::stream::{FusedStream, StreamExt};
use tokio::net::TcpStream;
use tokio::sync::broadcast;
use tokio::time::sleep;
use tokio_tungstenite::tungstenite::Result;
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream, connect_async};
use tracing::{debug, warn};
use vader_sentimental::SentimentIntensityAnalyzer;

const RETRY_DELAY: Duration = Duration::from_millis(5000);

const JETSTREAM_URI: &str =
    "wss://jetstream2.us-west.bsky.network/subscribe?wantedCollections=app.bsky.feed.post";
pub struct Jetstream<'a> {
    pub(crate) client: WebSocketStream<MaybeTlsStream<TcpStream>>,
    sia: SentimentIntensityAnalyzer<'a>,
    post_sender: broadcast::Sender<ProcessedPost>,
}

fn _get_langs(message: &Message) -> Option<&Vec<String>> {
    message.commit.as_ref()?.record.as_ref()?.langs.as_ref()
}

impl<'a> Jetstream<'a> {
    pub async fn connect(post_sender: &broadcast::Sender<ProcessedPost>) -> Result<Jetstream<'a>> {
        Ok(Jetstream {
            client: connect_async(JETSTREAM_URI).await?.0,
            sia: SentimentIntensityAnalyzer::new(),
            post_sender: post_sender.clone(),
        })
    }

    pub async fn reconnect_loop(mut self) {
        let mut reconnect_counter: usize = 0;
        loop {
            if self.client.is_terminated() {
                sleep(RETRY_DELAY).await;
                warn!("Attempting to reconnect");
                let new_client = match connect_async(JETSTREAM_URI).await {
                    Ok(v) => v.0,
                    Err(_) => {
                        warn!("Connection attempt {} failed", reconnect_counter);
                        reconnect_counter += 1;
                        continue;
                    }
                };
                self.client = new_client;
            }
            reconnect_counter = 0;
            self.recv_loop().await;
            debug!("Receive loop exited");
        }
    }

    pub async fn recv_loop(&mut self) {
        while let Some(message) = self.client.next().await {
            let raw = match message {
                Ok(d) => &*d.into_data(),
                Err(e) => {
                    warn!("Error receiving message: {:?}", e);
                    continue;
                }
            };
            match serde_json::from_slice::<Message>(raw) {
                Ok(v) => {
                    // Skip if languages do not include "en" or languages are unset
                    let en_in_langs = _get_langs(&v).is_some_and(|v| v.iter().any(|l| l == "en"));
                    if !en_in_langs {
                        continue;
                    }

                    let ppm = ProcessedPost::from_message(&v, &self.sia);
                    if ppm.sentiment < 0.0 {
                        let send_result = self.post_sender.send(ppm);
                        if send_result.is_err() {
                            // Expected if there are no receivers
                            continue;
                        }
                    }
                }
                Err(_) => {}
            }
        }
    }
}
