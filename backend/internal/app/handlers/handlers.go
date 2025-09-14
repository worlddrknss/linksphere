package handlers

import (
	"fmt"
	"net/http"
	"os"
)

func Home(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Server running on port %s\n", os.Getenv("PORT"))
}

func GetUrl(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Fetch URL metadata"))
}

func UpdateUrl(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("Update URL"))
}

// Health function handles health check requests
func Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintln(w, `{"status": "healthy"}`)
}
