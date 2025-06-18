package routes

import (
	"github.com/ExMe4/BluFeed/backend/handlers"
	"github.com/gofiber/fiber/v2"
)

func Register(app *fiber.App) {
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("BluFeed backend is running")
	})
	app.Post("/api/auth/google", handlers.GoogleLogin)
	app.Post("/api/reddit/feed", handlers.RedditFeed)
	app.Post("/api/reddit/token", handlers.RedditToken)
}
