package config_test

import (
	"errors"
	"testing"

	"github.com/schmitthub/blackbox/internal/config"
)

func env(vars map[string]string) func(string) string {
	return func(key string) string { return vars[key] }
}

func TestLoad(t *testing.T) {
	cfg, err := config.Load(env(map[string]string{"DATABASE_URL": "postgres://db"}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg.Addr != ":8080" {
		t.Errorf("default Addr = %q, want %q", cfg.Addr, ":8080")
	}

	cfg, err = config.Load(env(map[string]string{"DATABASE_URL": "postgres://db", "ADDR": ":9000"}))
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if cfg.Addr != ":9000" || cfg.DatabaseURL != "postgres://db" {
		t.Errorf("Load = %+v", cfg)
	}
}

func TestLoadMissingDatabaseURL(t *testing.T) {
	_, err := config.Load(env(nil))
	if !errors.Is(err, config.ErrMissingDatabaseURL) {
		t.Errorf("err = %v, want %v", err, config.ErrMissingDatabaseURL)
	}
}
