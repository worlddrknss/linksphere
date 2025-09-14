package handlers

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"math/big"
	"net/http"
	"os"
	"time"

	"github.com/WorldDrknss/LinkSphere/backend/cmd/db"
)

type CreateURLRequest struct {
	URL string `json:"url"`
}

type CreateURLResponse struct {
	Alias    string `json:"alias"`
	ShortURL string `json:"shortUrl"`
}

func secureAlias(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, n)

	for i := range b {
		num, _ := rand.Int(rand.Reader, big.NewInt(int64(len(letters))))
		b[i] = letters[num.Int64()]
	}
	return string(b)
}

func CreateUrl(w http.ResponseWriter, r *http.Request) {
	var req CreateURLRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if req.URL == "" {
		http.Error(w, "url is required", http.StatusBadRequest)
		return
	}

	// Generate alias
	alias := secureAlias(6)

	// Insert into DB
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := db.Pool.Exec(ctx, "INSERT INTO urls(alias, url) VALUES ($1, $2)", alias, req.URL)
	if err != nil {
		http.Error(w, "could not save link", http.StatusInternalServerError)
		return
	}

	baseURL := os.Getenv("BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:8080"
	}

	resp := CreateURLResponse{
		Alias:    alias,
		ShortURL: baseURL + "/" + alias,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
