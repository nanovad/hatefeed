package feed

import (
	"hatefeed/sentiment"
	"log"
	"time"

	"github.com/drankou/go-vader/vader"
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
	Did       string  `json:"did"`
	Rkey      string  `json:"rkey"`
	Sentiment float64 `json:"sentiment"`
}

type Feed struct {
	Fanout Fanout
}

func readAndFanMessage(conn *websocket.Conn, analyzer *vader.SentimentIntensityAnalyzer, onData func(ProcessedPost)) error {
	var x jetstreamMessage
	err := conn.ReadJSON(&x)
	if err != nil {
		return err
	}

	body := x.Commit.Record.Text
	lang := ""
	if len(x.Commit.Record.Langs) > 0 {
		lang = x.Commit.Record.Langs[0]
	}

	if x.Kind == "commit" && body != "" && lang == "en" {
		s := sentiment.ComputeSentiment(analyzer, body)

		if s <= -0.75 {
			onData(ProcessedPost{
				At:        0,
				Text:      body,
				Handle:    "handle",
				Did:       x.Did,
				Rkey:      x.Commit.Rkey,
				Sentiment: s,
			})
		}
	}
	return nil
}

func RunFeed(onData func(post ProcessedPost)) error {
	feedBackoffDuration := 4 // seconds
	// Exponential backoff means we'll retry after 4, 4+16, 20+64, 84+256, and
	// 340+1024 seconds
	// (from the first error, 4 seconds, 20 seconds, about 1.5 minutes,
	// 6 minutes, and about 22 mins)
	feedReconnectAttempts := 0
	consecutiveMessageReadAttempts := 0

	for feedReconnectAttempts < 5 {
		conn, _, err := websocket.DefaultDialer.Dial(jetstreamUri, nil)
		if err != nil {
			log.Printf("Failed to dial Jetstream websocket: %s\n", err.Error())
		} else {
			// Reset these variables if we successfully connect after a failed connection
			feedReconnectAttempts = 0
			feedBackoffDuration = 4

			log.Println("Connected to Jetstream")

			analyzer := sentiment.SetupAnalyzer()
			for {
				if err := readAndFanMessage(conn, &analyzer, onData); err != nil {
					log.Printf("Error fanning message: %s\n", err)
					consecutiveMessageReadAttempts++
					if consecutiveMessageReadAttempts > 3 {
						log.Println("Feed message fan attempts exceeded, trying to reconnect instead")
						consecutiveMessageReadAttempts = 0
						break
					}
				}
			}
		}

		feedReconnectAttempts++
		log.Printf("Sleeping for %ds before retrying connection\n", feedBackoffDuration)
		time.Sleep(time.Duration(feedBackoffDuration * int(time.Second)))
		feedBackoffDuration *= 4
	}
	log.Fatal("Feed reconnect attempts exceeded, quitting")
	return nil // Technically unreachable; silence a warning about not returning anything
}
