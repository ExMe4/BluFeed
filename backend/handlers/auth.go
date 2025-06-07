package handlers

import (
	"context"
	"os"

	"github.com/ExMe4/BluFeed/backend/database"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
)

type GoogleIDToken struct {
	Token string `json:"token"`
}

type GoogleUserInfo struct {
	Email string `json:"email"`
}

func GoogleLogin(c *fiber.Ctx) error {
	println("GoogleLogin handler hit")
	var payload GoogleIDToken
	if err := c.BodyParser(&payload); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid token payload"})
	}

	clientID := os.Getenv("GCLOUD_CLIENTID")
	payloadInfo, err := idtoken.Validate(context.Background(), payload.Token, clientID)
	if err != nil {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid Google ID token"})
	}

	email, ok := payloadInfo.Claims["email"].(string)
	if !ok || email == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Email not found in token"})
	}

	var exists bool
	err = database.DB.QueryRow(context.Background(), "SELECT EXISTS(SELECT 1 FROM users WHERE email=$1)", email).Scan(&exists)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "DB query failed"})
	}

	var userID string
	if exists {
		err = database.DB.QueryRow(context.Background(), "SELECT id FROM users WHERE email=$1", email).Scan(&userID)
	} else {
		userID = uuid.New().String()
		_, err = database.DB.Exec(context.Background(), "INSERT INTO users (id, email) VALUES ($1, $2)", userID, email)
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "DB insert failed"})
	}

	return c.JSON(fiber.Map{"id": userID, "email": email})
}
