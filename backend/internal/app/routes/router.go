package routes

import (
	"github.com/WorldDrknss/LinkSphere/backend/internal/app/handlers"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func SetupRoutes() *chi.Mux {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Heartbeat("/ping"))

	// Routes
	r.Get("/", handlers.Home)
	r.Get("/about", handlers.About)
	
	// API routes
r.Route("/api", func(r chi.Router) {
    r.Route("/v1", func(r chi.Router) {
        // Healthcheck
        r.Get("/health", handlers.Health)

        // URLs
        r.Route("/urls", func(r chi.Router) {
            r.Post("/", handlers.CreateUrl)
            r.Get("/{alias}", handlers.GetUrl)
            r.Put("/{alias}", handlers.UpdateUrl)
            r.Delete("/{alias}", handlers.DeleteUrl)
        })
    })
})

	return r
}
