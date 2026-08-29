package main

// hub.go — latest-value broadcast to all WebSocket connections.
//
// Every subscriber receives each snapshot at most once; missed ticks are
// implicitly skipped (thin-client rendering model). A channel-based design
// is used instead of sync.Cond so that WaitCtx can honour context cancellation
// and the 15-second keepalive timeout without polling.

import (
	"context"
	"sync"
	"time"
)

// Hub fans the most recent snapshot out to every waiting subscriber.
type Hub struct {
	mu      sync.Mutex
	seq     int
	data    string
	waiters []chan struct{}
}

// NewHub returns an empty hub with seq=0.
func NewHub() *Hub {
	return &Hub{data: "{}"}
}

// Seq returns the current snapshot sequence number (safe for concurrent use).
func (h *Hub) Seq() int {
	h.mu.Lock()
	s := h.seq
	h.mu.Unlock()
	return s
}

// Publish stores the latest snapshot, bumps the sequence number, and wakes
// every subscriber. Corresponds to Python's Hub.publish().
func (h *Hub) Publish(data string) {
	h.mu.Lock()
	h.data = data
	h.seq++
	ws := h.waiters
	h.waiters = nil
	h.mu.Unlock()
	for _, ch := range ws {
		close(ch)
	}
}

// WaitCtx blocks until a snapshot newer than lastSeq is available, the
// timeout elapses, or ctx is cancelled.  Returns ("", lastSeq) on timeout or
// cancellation so the caller can send a keepalive and loop.
func (h *Hub) WaitCtx(ctx context.Context, lastSeq int, timeout time.Duration) (int, string) {
	h.mu.Lock()
	if h.seq != lastSeq {
		seq, data := h.seq, h.data
		h.mu.Unlock()
		return seq, data
	}
	ch := make(chan struct{})
	h.waiters = append(h.waiters, ch)
	h.mu.Unlock()

	select {
	case <-ch:
		// Publish fired.
	case <-time.After(timeout):
		h.removeWaiter(ch)
		return lastSeq, ""
	case <-ctx.Done():
		h.removeWaiter(ch)
		return lastSeq, ""
	}

	h.mu.Lock()
	seq, data := h.seq, h.data
	h.mu.Unlock()
	return seq, data
}

// removeWaiter removes ch from the pending waiters list (no-op if already
// removed by Publish).
func (h *Hub) removeWaiter(ch chan struct{}) {
	h.mu.Lock()
	for i, w := range h.waiters {
		if w == ch {
			last := len(h.waiters) - 1
			h.waiters[i] = h.waiters[last]
			h.waiters = h.waiters[:last]
			break
		}
	}
	h.mu.Unlock()
}
