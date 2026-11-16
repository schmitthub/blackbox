//go:build integration

package api_test

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/schmitthub/blackbox/internal/api"
	"github.com/schmitthub/blackbox/internal/config"
)

func TestHealthWithDatabase(t *testing.T) {
	gin.SetMode(gin.TestMode)

	cfg, err := config.Load()
	require.NoError(t, err)

	pool, err := pgxpool.New(t.Context(), cfg.DatabaseURL)
	require.NoError(t, err)
	t.Cleanup(pool.Close)

	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/healthz", nil)

	api.NewRouter(pool).ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	assert.JSONEq(t, `{"status":"ok"}`, rec.Body.String())
}
