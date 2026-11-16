// Command mcp serves Blackbox to MCP clients.
package main

import (
	"log/slog"
	"os"

	"github.com/schmitthub/blackbox/mcp/internal/server"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stderr, nil))

	if err := server.Run(); err != nil {
		logger.Error("mcp stopped", "error", err)
		os.Exit(1)
	}
}
