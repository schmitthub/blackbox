// Package server runs the HTTP server and shuts it down gracefully.
package server

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"time"
)

const (
	readHeaderTimeout = 10 * time.Second
	shutdownTimeout   = 15 * time.Second
)

// Run serves handler on addr until ctx is cancelled, then waits up to
// shutdownTimeout for in-flight requests to finish.
func Run(ctx context.Context, addr string, handler http.Handler, logger *slog.Logger) error {
	var lc net.ListenConfig

	listener, err := lc.Listen(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("listen on %s: %w", addr, err)
	}

	srv := &http.Server{Handler: handler, ReadHeaderTimeout: readHeaderTimeout}
	serveErr := make(chan error, 1)

	go func() { serveErr <- srv.Serve(listener) }()

	logger.InfoContext(ctx, "listening", "addr", listener.Addr().String())

	select {
	case err = <-serveErr:
		return fmt.Errorf("serve: %w", err)
	case <-ctx.Done():
	}

	logger.InfoContext(ctx, "shutting down")

	// ctx is already cancelled; the shutdown deadline needs a live one.
	shutdownCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), shutdownTimeout)
	defer cancel()

	if err = srv.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("shutdown: %w", err)
	}

	if err = <-serveErr; !errors.Is(err, http.ErrServerClosed) {
		return fmt.Errorf("serve: %w", err)
	}

	return nil
}
