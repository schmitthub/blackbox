package server_test

import (
	"context"
	"log/slog"
	"net/http"
	"testing"

	"github.com/schmitthub/blackbox/core/internal/server"
)

func TestRunStopsOnCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	cancel()

	err := server.Run(ctx, "127.0.0.1:0", http.NotFoundHandler(), slog.New(slog.DiscardHandler))
	if err != nil {
		t.Errorf("Run = %v, want nil", err)
	}
}

func TestRunBadAddress(t *testing.T) {
	err := server.Run(t.Context(), "not an address", http.NotFoundHandler(), slog.New(slog.DiscardHandler))
	if err == nil {
		t.Error("Run = nil, want a listen error")
	}
}
