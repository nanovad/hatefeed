package feed

import (
	"fmt"
	"sync"
	"sync/atomic"
)

type ProcessedPostChannelId uint64

type ProcessedPostChannel struct {
	Id      ProcessedPostChannelId
	Channel chan ProcessedPost
}

type Fanout struct {
	mu     sync.RWMutex
	nextId atomic.Uint64
	subs   map[ProcessedPostChannelId]*ProcessedPostChannel
}

func NewFanout() *Fanout {
	var f Fanout
	f.subs = make(map[ProcessedPostChannelId]*ProcessedPostChannel)
	return &f
}

func (f *Fanout) getNextId() ProcessedPostChannelId {
	return ProcessedPostChannelId(f.nextId.Add(1))
}

func (f *Fanout) Subscribe() *ProcessedPostChannel {
	f.mu.Lock()
	defer f.mu.Unlock()

	id := f.getNextId()

	ppc := ProcessedPostChannel{
		Id:      id,
		Channel: make(chan ProcessedPost, 50),
	}

	f.subs[id] = &ppc

	fmt.Printf("Subscribed fanout receiver %d - %d receivers now connected\n", id, len(f.subs))

	return &ppc
}

func (f *Fanout) Unsubscribe(Id ProcessedPostChannelId) {
	f.mu.Lock()
	defer f.mu.Unlock()

	delete(f.subs, Id)

	fmt.Printf("Fanout receiver %d disconnected - %d receivers now connected\n", Id, len(f.subs))
}

func (f *Fanout) Publish(msg ProcessedPost) {
	f.mu.Lock()
	defer f.mu.Unlock()
	for _, ppc := range f.subs {
		// TODO: How's the performance of this fanout?
		select {
		case ppc.Channel <- msg:
			// Message sent to the receiver successfully
		default:
			fmt.Printf("Warning: channel for receiver %d is full, dropping message\n", ppc.Id)
		}
	}
}
