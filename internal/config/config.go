// Package config loads the service configuration from the environment.
package config

import "errors"

const defaultAddr = ":8080"

// ErrMissingDatabaseURL is returned when DATABASE_URL is not set.
var ErrMissingDatabaseURL = errors.New("DATABASE_URL is not set")

// Config is the service configuration.
type Config struct {
	// Addr is the address the HTTP server listens on.
	Addr string
	// DatabaseURL is the PostgreSQL connection string.
	DatabaseURL string
}

// Load reads the configuration through getenv, normally [os.Getenv].
func Load(getenv func(string) string) (Config, error) {
	cfg := Config{
		Addr:        getenv("ADDR"),
		DatabaseURL: getenv("DATABASE_URL"),
	}

	if cfg.Addr == "" {
		cfg.Addr = defaultAddr
	}

	if cfg.DatabaseURL == "" {
		return Config{}, ErrMissingDatabaseURL
	}

	return cfg, nil
}
