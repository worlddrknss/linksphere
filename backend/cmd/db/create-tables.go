package db

import (
	"context"
	"time"
)

func AutoMigrate() error {
	query := `
	CREATE TABLE IF NOT EXISTS urls (
		id SERIAL PRIMARY KEY,
		alias VARCHAR(20) UNIQUE NOT NULL,
		url TEXT NOT NULL,
		clicks INT DEFAULT 0,
		created_at TIMESTAMP DEFAULT now()
	)`
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := Pool.Exec(ctx, query)
	return err
}
