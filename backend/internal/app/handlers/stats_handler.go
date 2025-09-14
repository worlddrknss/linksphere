package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/WorldDrknss/LinkSphere/backend/cmd/db"
)

type TopURL struct {
	Alias  string `json:"alias"`
	URL    string `json:"url"`
	Clicks int64  `json:"clicks"`
}

type StatsResponse struct {
	TotalURLs   int64   `json:"totalUrls"`
	TotalClicks int64   `json:"totalClicks"`
	TopURL      *TopURL `json:"topUrl,omitempty"`
}

// Stats returns aggregate statistics about stored URLs
func Stats(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	var totalURLs int64
	err := db.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM urls").Scan(&totalURLs)
	if err != nil {
		http.Error(w, "could not fetch total urls", http.StatusInternalServerError)
		return
	}

	var totalClicks int64
	err = db.Pool.QueryRow(ctx, "SELECT COALESCE(SUM(clicks),0) FROM urls").Scan(&totalClicks)
	if err != nil {
		http.Error(w, "could not fetch total clicks", http.StatusInternalServerError)
		return
	}

	var top TopURL
	err = db.Pool.QueryRow(ctx, "SELECT alias, url, clicks FROM urls ORDER BY clicks DESC LIMIT 1").Scan(&top.Alias, &top.URL, &top.Clicks)
	if err != nil {
		// If no rows exist, return empty topUrl
		top = TopURL{}
		resp := StatsResponse{TotalURLs: totalURLs, TotalClicks: totalClicks, TopURL: nil}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
		return
	}

	resp := StatsResponse{TotalURLs: totalURLs, TotalClicks: totalClicks, TopURL: &top}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
