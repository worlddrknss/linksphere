package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/WorldDrknss/LinkSphere/backend/cmd/db"
)

// URLItem represents a single stored URL row returned to admin clients
type URLItem struct {
	Alias  string `json:"alias"`
	URL    string `json:"url"`
	Clicks int64  `json:"clicks"`
}

// ListUrlsResponse is the paginated response returned by ListUrls
type ListUrlsResponse struct {
	Total      int64     `json:"total"`
	Page       int       `json:"page"`
	Limit      int       `json:"limit"`
	TotalPages int       `json:"totalPages"`
	Items      []URLItem `json:"items"`
}

// ListUrls returns a paginated list of urls with alias and clicks.
// Query params:
//   - page (default 1)
//   - limit (default 20, max 100)
func ListUrls(w http.ResponseWriter, r *http.Request) {
	// parse query params
	q := r.URL.Query()
	page := 1
	limit := 20

	if p := q.Get("page"); p != "" {
		if v, err := strconv.Atoi(p); err == nil && v > 0 {
			page = v
		}
	}
	if l := q.Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}
	if limit > 100 {
		limit = 100
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	// total count
	var total int64
	err := db.Pool.QueryRow(ctx, "SELECT COUNT(*) FROM urls").Scan(&total)
	if err != nil {
		http.Error(w, "could not fetch total urls", http.StatusInternalServerError)
		return
	}

	// calculate offset
	offset := (page - 1) * limit

	// fetch rows
	rows, err := db.Pool.Query(ctx, "SELECT alias, url, clicks FROM urls ORDER BY created_at DESC LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		http.Error(w, "could not fetch urls", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	items := make([]URLItem, 0)
	for rows.Next() {
		var it URLItem
		if err := rows.Scan(&it.Alias, &it.URL, &it.Clicks); err != nil {
			http.Error(w, "error scanning urls", http.StatusInternalServerError)
			return
		}
		items = append(items, it)
	}
	if rows.Err() != nil {
		http.Error(w, "error reading urls", http.StatusInternalServerError)
		return
	}

	totalPages := 0
	if total > 0 {
		totalPages = int((total + int64(limit) - 1) / int64(limit))
	}

	resp := ListUrlsResponse{
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
		Items:      items,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		// writing response failed
		http.Error(w, fmt.Sprintf("could not encode response: %v", err), http.StatusInternalServerError)
		return
	}
}
