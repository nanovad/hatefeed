package main

import (
	"bytes"
	"fmt"
	"hatefeed/feed"
	"log"
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
	fmt.Printf("Hatefeed daemon v0.2.1\n")
	http.HandleFunc("/", respond)
	go http.ListenAndServe(":8080", nil)

	feed.RunFeed(receivedMessage)
}

func respond(w http.ResponseWriter, r *http.Request) {
	connection, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Printf("Unable to upgrade client request: %s\n", err.Error())
		connection.Close() // ignore close error
	}
	fmt.Printf("Upgraded client request from %s to websocket", r.RemoteAddr)

	// Create a fanout receiver
	ppc := fanout.Subscribe()

	connection.SetCloseHandler(func(code int, text string) error {
		fanout.Unsubscribe(ppc.Id)
		return nil
	})

	_, data, err := connection.ReadMessage()
	if err != nil {
		log.Printf("Failed to connect to client: %s. Closing", err.Error())
		return
	}
	if bytes.Equal(data, []byte("READY")) {
		connection.WriteMessage(websocket.TextMessage, []byte("OKAYLESGO"))
	}

	for {
		msg := <-ppc.Channel
		if err := connection.WriteJSON(msg); err != nil {
			fanout.Unsubscribe(ppc.Id)
			connection.Close()
			break
		}
	}
}

func receivedMessage(p feed.ProcessedPost) {
	fanout.Publish(p)
}
