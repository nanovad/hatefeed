package feed

import (
	"hatefeed/sentiment"
	"log"

	"github.com/gorilla/websocket"
)

// TODO: Enable compression
var jetstreamUri = "wss://jetstream2.us-west.bsky.network/subscribe?wantedCollections=app.bsky.feed.post"

type jetstreamMessage struct {
	Did    string
	TimeUs int64 `json:"time_us"`
	Kind   string
	Commit jetstreamCommit
}

type jetstreamCommit struct {
	Rev        string
	Operation  string
	Collection string
	Rkey       string
	Record     jetstreamRecord
	Cid        string
}

type jetstreamRecord struct {
	RecordType string
	CreatedAt  string
	Subject    struct {
		Cid string
		Uri string
	}
	Text  string
	Langs []string
}

type ProcessedPost struct {
	At        uint64  `json:"at"`
	Text      string  `json:"text"`
	Handle    string  `json:"handle"`
	Sentiment float64 `json:"sentiment"`
}

type Feed struct {
	Fanout Fanout
}

func RunFeed(onData func(post ProcessedPost)) {
	conn, _, err := websocket.DefaultDialer.Dial(jetstreamUri, nil)
	if err != nil {
		log.Fatal(err)
	}

	analyzer := sentiment.SetupAnalyzer()

	for {
		// var asdf map[string]any
		var x jetstreamMessage
		err = conn.ReadJSON(&x)
		if err != nil {
			log.Fatal(err)
		}

		body := x.Commit.Record.Text
		lang := ""
		if len(x.Commit.Record.Langs) > 0 {
			lang = x.Commit.Record.Langs[0]
		}

		if x.Kind == "commit" && body != "" && lang == "en" {
			s := sentiment.ComputeSentiment(&analyzer, body)

			if s <= -0.5 {
				onData(ProcessedPost{
					At:        0,
					Text:      body,
					Handle:    "handle",
					Sentiment: s,
				})
			}
		}

	}
}
