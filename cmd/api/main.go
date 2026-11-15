package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	db, err := sql.Open("pgx", os.Getenv("DATABASE_URL"))
	if err != nil {
		return fmt.Errorf("open database: %w", err)
	}
	defer db.Close()

	r := gin.Default()
	r.GET("/healthz", func(c *gin.Context) {
		if pingErr := db.PingContext(c.Request.Context()); pingErr != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "db unavailable"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	if err = r.Run(":8080"); err != nil {
		return fmt.Errorf("serve: %w", err)
	}
	return nil
}
