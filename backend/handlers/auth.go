package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/ExMe4/BluFeed/backend/database"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type GoogleIDToken struct {
	Token string `json:"token"`
}

type GoogleUserInfo struct {
	Email string `json:"email"`
}

func GoogleLogin(c *fiber.Ctx) error {
	var payload GoogleIDToken
	if err := c.BodyParser(&payload); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid token payload"})
	}

	// Sends token to Google's verification endpoint
	resp, err := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + payload.Token)
	if err != nil || resp.StatusCode != 200 {
		return c.Status(401).JSON(fiber.Map{"error": "Invalid Google ID token"})
	}
	defer resp.Body.Close()

	var userInfo GoogleUserInfo
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse Google response"})
	}

	// Checks if user exists in DB
	var exists bool
	err = database.DB.QueryRow(context.Background(), "SELECT EXISTS(SELECT 1 FROM users WHERE email=$1)", userInfo.Email).Scan(&exists)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "DB query failed"})
	}

	var userID string
	if exists {
		// Gets existing ID
		err = database.DB.QueryRow(context.Background(), "SELECT id FROM users WHERE email=$1", userInfo.Email).Scan(&userID)
	} else {
		// Creates new user
		userID = uuid.New().String()
		_, err = database.DB.Exec(context.Background(),
			"INSERT INTO users (id, email) VALUES ($1, $2)", userID, userInfo.Email,
		)
	}
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "DB insert failed"})
	}

	return c.JSON(fiber.Map{
		"id":    userID,
		"email": userInfo.Email,
	})
}
