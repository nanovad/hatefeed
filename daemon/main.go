package main

import (
	"fmt"
	"hatefeed/client"
	"hatefeed/feed"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
	// EnableCompression: true,
}

// var posts = make(chan feed.ProcessedPost)

var fanout = feed.NewFanout()

func main() {
	fmt.Printf("Hatefeed daemon v0.3.0\n")
	http.HandleFunc("/", respond)
	go http.ListenAndServe("127.0.0.1:8080", nil)

	feed.RunFeed(feedReceivedMessage)
}

func respond(w http.ResponseWriter, r *http.Request) {
	connection, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Printf("Unable to upgrade client request: %s\n", err.Error())
		connection.Close() // ignore close error
	}
	fmt.Printf("Upgraded client request from %s to websocket\n", r.RemoteAddr)

	feedClient := client.NewClient(fanout, connection)

	connection.SetCloseHandler(func(code int, text string) error {
		feedClient.Quit()
		return nil
	})

	feedClient.RunClient()
}

func feedReceivedMessage(p feed.ProcessedPost) {
	fanout.Publish(p)
}
