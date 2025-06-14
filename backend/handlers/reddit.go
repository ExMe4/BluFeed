package handlers

import (
	"encoding/json"
	"io"
	"log"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type RedditToken struct {
	Token string `json:"token"`
}

func RedditFeed(c *fiber.Ctx) error {
	var body RedditToken
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid payload"})
	}

	req, err := http.NewRequest("GET", "https://oauth.reddit.com/best", nil)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create request"})
	}

	log.Println("Using Reddit Token:", body.Token)

	req.Header.Set("Authorization", "Bearer "+body.Token)
	req.Header.Set("User-Agent", "BluFeed/0.1")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Request to Reddit failed"})
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	log.Println("Reddit Response Status:", resp.Status)

	if resp.StatusCode != http.StatusOK {
		bodyText, _ := io.ReadAll(resp.Body)
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error":  "Reddit returned error",
			"status": resp.StatusCode,
			"body":   string(bodyText),
		})
	}

	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to read response"})
	}

	var jsonBody interface{}
	if err := json.Unmarshal(bodyBytes, &jsonBody); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Invalid JSON from Reddit"})
	}

	return c.JSON(jsonBody)
}
