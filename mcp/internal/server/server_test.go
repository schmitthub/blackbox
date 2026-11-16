package server_test

import (
	"testing"

	"github.com/schmitthub/blackbox/mcp/internal/server"
)

func TestRun(t *testing.T) {
	err := server.Run()
	if err == nil {
		t.Fatal("Run returned nil, want ErrNotImplemented")
	}
}
