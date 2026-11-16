// Package server is the MCP server.
package server

import "errors"

// ErrNotImplemented reports that the server is still a scaffold.
var ErrNotImplemented = errors.New("mcp server is not implemented")

// Run serves MCP until the client disconnects.
func Run() error {
	return ErrNotImplemented
}
