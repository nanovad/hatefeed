package client

import (
	"bytes"
	"fmt"
	"hatefeed/feed"
	"hatefeed/profile"
	"log"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

type Client struct {
	quitting       chan bool
	fanout         *feed.Fanout
	ppc            *feed.ProcessedPostChannel
	connection     *websocket.Conn
	hatestack      *feed.Hatestack
	feedMode       FeedMode
	targetInterval atomic.Uint32
	threshold      atomic.Int32
}

func (c *Client) handshake() (err error) {
	// Wait for the client to indicate they are ready
	_, data, err := c.connection.ReadMessage()
	if err != nil || !bytes.Equal(data, []byte(MSG_HANDSHAKE_CLIENT_READY)) {
		return fmt.Errorf("error waiting for READY message from client")
	}

	c.connection.WriteMessage(websocket.TextMessage, []byte(MSG_HANDSHAKE_SERVER_REPLY))

	return nil
}

func NewClient(f *feed.Fanout, connection *websocket.Conn) *Client {
	c := Client{
		quitting:       make(chan bool),
		fanout:         f,
		ppc:            f.Subscribe(),
		connection:     connection,
		hatestack:      feed.NewHatestack(50),
		feedMode:       FEED_MODE_RATE,
		targetInterval: atomic.Uint32{}, // Target message interval, milliseconds
		threshold:      atomic.Int32{},  // Target message sentiment threshold, x 100
	}

	c.targetInterval.Store(2000)
	c.threshold.Store(-0.75 * 100)
	return &c
}

func (c *Client) RunClient() {
	// Try to handshake with the client
	if err := c.handshake(); err != nil {
		log.Printf("Handshake failed for client")
		c.Quit()
		return
	}

	// Spin up the client message loop
	go c.clientMessageLoop()

	// The fanout receiver loop
	go c.fanoutReceiver()

	// And the feed sending loop
	go c.feedLoop()
}

func (c *Client) clientMessageLoop() {
	for {
		select {
		case <-c.quitting:
			return
		default:
			_, data, err := c.connection.ReadMessage()
			if err != nil {
				// TODO: Do we need to quit the other goroutines?
				return
			}
			dataStr := string(data)
			cc, err := ParseMessage(dataStr)
			if err != nil {
				log.Printf("error parsing message from client: %s\n", err.Error())
			}

			switch cc := cc.(type) {
			case ClientCommandInterval:
				interval := cc.Interval
				c.targetInterval.Store(interval)
			case ClientCommandThreshold:
				threshold := cc.Threshold
				c.threshold.Store(int32(threshold * 100))
			case ClientCommandFeedMode:
				mode := cc.Mode
				c.feedMode = mode
			default:
				log.Printf("unknown command from client\n")
			}
		}
	}
}

func (c *Client) fanoutReceiver() {
	for {
		select {
		case <-c.quitting:
			return
		default:
			// Retrieve from the fanout channel and add to the hatestack
			msg := <-c.ppc.Channel
			c.hatestack.Add(msg)
		}
	}
}

func (c *Client) feedLoop() {
	hc := profile.GetProfileCache()
	for {
		select {
		case <-c.quitting:
			return
		default:
			// Retrieve from the hatestack and send to client
			p := c.hatestack.Pop()
			// Sometimes the hatestack is empty, so we need to check for nil
			if p != nil {
				// Hydrate the profile. This is a network request and could be
				// slow, but this loop usually isn't running very quickly.
				profile, err := hc.ResolveProfile(p.Did)
				if err != nil {
					p.Handle = nil
					p.DisplayName = nil
				} else {
					p.Handle = &profile.Handle
					p.DisplayName = &profile.DisplayName
				}

				// We're using threshold mode but the sentiment is above the threshold - skip
				if c.feedMode == FEED_MODE_THRESHOLD && p.Sentiment >= float64(c.threshold.Load())/100 {
					// We also don't want to empty out the queue too fast / busy wait, so add a small delay
					time.Sleep(100 * time.Millisecond)
					continue
				}

				// Send the message to the client
				if err := c.connection.WriteJSON(p); err != nil {
					// If the message can't be sent, quit and disconnect the client
					// If this is a transient network issue, they will reconnect soon
					c.Quit()
					return
				}
			}

			// If we're in rate mode, sleep for the target interval
			if c.feedMode == FEED_MODE_RATE {
				time.Sleep(time.Duration(c.targetInterval.Load()) * time.Millisecond)
			}
		}
	}
}

func (c *Client) Quit() {
	close(c.quitting)
	c.fanout.Unsubscribe(c.ppc.Id)
	c.connection.Close()
}
