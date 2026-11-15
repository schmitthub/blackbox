// Package api holds the HTTP routes and their handlers.
package api

import (
	"context"

	"github.com/gin-gonic/gin"
)

// Pinger reports whether the database answers.
type Pinger interface {
	Ping(ctx context.Context) error
}

type handler struct {
	db Pinger
}

// NewRouter returns the API routes, served from db.
func NewRouter(db Pinger) *gin.Engine {
	h := &handler{db: db}

	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())
	router.GET("/healthz", h.health)

	return router
}
