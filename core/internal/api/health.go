package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// health answers 200 when the database is reachable and 503 when it is not.
func (h *handler) health(c *gin.Context) {
	if err := h.db.Ping(c.Request.Context()); err != nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"status": "db unavailable"})

		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
