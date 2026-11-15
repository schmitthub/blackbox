package api_test

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"github.com/stretchr/testify/mock"

	"github.com/schmitthub/blackbox/internal/api"
	"github.com/schmitthub/blackbox/internal/api/mocks"
)

func TestHealth(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name     string
		err      error
		wantCode int
		wantBody string
	}{
		{"database up", nil, http.StatusOK, `{"status":"ok"}`},
		{"database down", errors.New("refused"), http.StatusServiceUnavailable, `{"status":"db unavailable"}`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequestWithContext(t.Context(), http.MethodGet, "/healthz", nil)

			db := mocks.NewMockPinger(t)
			db.EXPECT().Ping(mock.Anything).Return(tt.err)

			api.NewRouter(db).ServeHTTP(rec, req)

			if rec.Code != tt.wantCode {
				t.Errorf("status = %d, want %d", rec.Code, tt.wantCode)
			}

			if got := rec.Body.String(); got != tt.wantBody {
				t.Errorf("body = %s, want %s", got, tt.wantBody)
			}
		})
	}
}
