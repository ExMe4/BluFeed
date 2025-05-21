package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"

	"github.com/ExMe4/BluFeed/backend/database"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("No .env file found, proceeding without it.")
	}

	database.Connect()

	app := fiber.New()

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("BluFeed backend is running")
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	log.Fatal(app.Listen(":" + port))
}
