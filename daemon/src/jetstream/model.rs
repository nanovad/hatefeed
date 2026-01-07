use demoji::Demoji;
use serde::{Deserialize, Serialize};
use vader_sentimental::SentimentIntensityAnalyzer;

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)]
pub struct Message {
    pub did: String,
    pub time_us: i64,
    pub kind: String,
    pub commit: Option<Commit>,
}

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)]
pub struct Commit {
    pub rev: String,
    pub operation: String,
    pub collection: String,
    pub rkey: String,
    pub record: Option<Record>,
    pub cid: Option<String>,
}

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)]
pub struct Subject {
    pub cid: String,
    pub uri: String,
}

#[derive(Deserialize, Debug, Clone)]
#[allow(dead_code)]
pub struct Record {
    #[serde(rename = "$type")]
    pub record_type: String,
    #[serde(rename = "createdAt")]
    pub created_at: String,
    pub subject: Option<Subject>,
    pub text: String,
    pub langs: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct TokenSentiment {
    pub token: String,
    pub score: f64,
}

#[derive(Debug, Clone, Serialize, PartialEq)]
pub struct ProcessedPost {
    pub at: i64,
    pub text: String,
    pub handle: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    pub did: String,
    pub rkey: String,
    pub sentiment: f64,
    #[serde(rename = "tokenSentiments")]
    pub token_sentiments: Vec<TokenSentiment>,
}

impl ProcessedPost {
    pub fn from_message(m: &Message, sia: &SentimentIntensityAnalyzer) -> Self {
        let mut text = "".to_string();
        let mut rkey = "".to_string();
        match &m.commit {
            Some(v) => {
                rkey = v.rkey.clone();
                match &v.record {
                    Some(r) => {
                        text = r.text.clone();
                    }
                    None => {}
                }
            }
            None => {}
        }

        let demojid = text.demojify();

        let ts: Vec<TokenSentiment> = demojid
            .split_inclusive(|c: char| c.is_whitespace())
            .map(|v| TokenSentiment {
                token: v.to_string(),
                score: sia.polarity_scores(v).compound,
            })
            .collect();

        ProcessedPost {
            // at: chrono::DateTime::from_timestamp_micros(m.time_us).unwrap(),
            at: m.time_us,
            text: text.clone(),
            handle: "<unknown>".to_string(),
            display_name: "<unknown>".to_string(),
            did: m.did.clone(),
            rkey,
            sentiment: sia.polarity_scores(demojid.as_str()).compound,
            token_sentiments: ts,
        }
    }
}
