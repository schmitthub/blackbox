// Package config loads the service configuration from the environment.
package config

import (
	"errors"
	"fmt"

	"github.com/spf13/viper"
)

const (
	keyAddr        = "addr"
	keyDatabaseURL = "database_url"

	defaultAddr = ":8080"
)

// ErrMissingDatabaseURL is returned when DATABASE_URL is not set.
var ErrMissingDatabaseURL = errors.New("DATABASE_URL is not set")

// Config is the service configuration.
type Config struct {
	// Addr is the address the HTTP server listens on. Environment: ADDR.
	Addr string `mapstructure:"addr"`
	// DatabaseURL is the PostgreSQL connection string. Environment: DATABASE_URL.
	DatabaseURL string `mapstructure:"database_url"`
}

// Load reads the configuration from the environment.
func Load() (Config, error) {
	v := viper.New()
	v.SetDefault(keyAddr, defaultAddr)

	// Each key binds to the environment variable of the same name, upper-cased.
	for _, key := range []string{keyAddr, keyDatabaseURL} {
		if err := v.BindEnv(key); err != nil {
			return Config{}, fmt.Errorf("bind %s: %w", key, err)
		}
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return Config{}, fmt.Errorf("unmarshal config: %w", err)
	}

	if cfg.DatabaseURL == "" {
		return Config{}, ErrMissingDatabaseURL
	}

	return cfg, nil
}
