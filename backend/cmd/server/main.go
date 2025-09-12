package main

import (
	"log"
	"net/http"
	"os"

	"github.com/WorldDrknss/LinkSphere/backend/cmd/db"
	"github.com/WorldDrknss/LinkSphere/backend/internal/app/routes"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env file
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, falling back to system env")
	}

	// Connect to DB
	if err := db.Connect(); err != nil {
		log.Fatalf("DB connection failed: %v", err)
	}
	defer db.Pool.Close()

	// Auto-migrate tables
	if err := db.AutoMigrate(); err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	// Setup routes
	r := routes.SetupRoutes()

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Fatal(http.ListenAndServe(":"+port, r))
}
