package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/WorldDrknss/LinkSphere/backend/cmd/db"
	"github.com/go-chi/chi/v5"
)

// DeleteUrl handles deleting a shortened URL by its alias.
func DeleteUrl(w http.ResponseWriter, r *http.Request) {
	alias := chi.URLParam(r, "alias")
	if alias == "" {
		http.Error(w, "alias is required", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cmdTag, err := db.Pool.Exec(ctx, "DELETE FROM urls WHERE alias = $1", alias)
	if err != nil {
		http.Error(w, "could not delete link", http.StatusInternalServerError)
		return
	}

	if cmdTag.RowsAffected() == 0 {
		http.Error(w, "alias not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
