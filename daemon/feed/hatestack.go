package feed

import (
	"cmp"
	"slices"
	"sync"
)

type Hatestack struct {
	Depth uint16
	Stack []ProcessedPost
	mu    sync.RWMutex
}

func NewHatestack(depth uint16) *Hatestack {
	return &Hatestack{
		Depth: depth,
		Stack: make([]ProcessedPost, 0, depth),
	}
}

func (s *Hatestack) Add(p ProcessedPost) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Remove the least negative sentiment item if the stack is full, to make
	// room for the new item.
	if len(s.Stack) == int(s.Depth) {
		s.Stack = s.Stack[len(s.Stack)-1:]
	}

	// Add the new item
	s.Stack = append(s.Stack, p)

	// Sort the stack by sentiment, ascending
	slices.SortFunc(s.Stack, func(a ProcessedPost, b ProcessedPost) int {
		return cmp.Compare(a.Sentiment, b.Sentiment)
	})
}

func (s *Hatestack) Pop() *ProcessedPost {
	s.mu.Lock()
	defer s.mu.Unlock()

	if len(s.Stack) == 0 {
		return nil
	}

	// The first item is the worst according to our sort method
	p := s.Stack[0]
	s.Stack = s.Stack[1:]
	return &p
}
