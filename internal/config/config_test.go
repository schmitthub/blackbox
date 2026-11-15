package config_test

import (
	"errors"
	"testing"

	"github.com/schmitthub/blackbox/internal/config"
)

func TestLoadDefaults(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://db")
	t.Setenv("ADDR", "")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	want := config.Config{Addr: ":8080", DatabaseURL: "postgres://db"}
	if cfg != want {
		t.Errorf("Load = %+v, want %+v", cfg, want)
	}
}

func TestLoadFromEnvironment(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://db")
	t.Setenv("ADDR", ":9000")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	want := config.Config{Addr: ":9000", DatabaseURL: "postgres://db"}
	if cfg != want {
		t.Errorf("Load = %+v, want %+v", cfg, want)
	}
}

func TestLoadMissingDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "")

	_, err := config.Load()
	if !errors.Is(err, config.ErrMissingDatabaseURL) {
		t.Errorf("err = %v, want %v", err, config.ErrMissingDatabaseURL)
	}
}
