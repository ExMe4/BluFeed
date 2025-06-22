package handlers

import (
	"encoding/base64"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type RedditAccessTokenRequest struct {
	Code        string `json:"code"`
	RedirectUri string `json:"redirect_uri"`
}

type RedditFeedRequest struct {
	Token string `json:"token"`
}

// POST /api/reddit/token
func RedditToken(c *fiber.Ctx) error {
	var body RedditAccessTokenRequest
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid payload"})
	}

	clientID := os.Getenv("REDDIT_CLIENT_ID")
	clientSecret := ""

	data := url.Values{}
	data.Set("grant_type", "authorization_code")
	data.Set("code", body.Code)
	data.Set("redirect_uri", "blufeed://auth-callback")

	req, err := http.NewRequest("POST", "https://www.reddit.com/api/v1/access_token", strings.NewReader(data.Encode()))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create request"})
	}

	authHeader := base64.StdEncoding.EncodeToString([]byte(clientID + ":" + clientSecret))
	req.Header.Add("Authorization", "Basic "+authHeader)
	req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	req.Header.Set("User-Agent", "BluFeed/0.1 by ExMe4")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Reddit token request failed"})
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to read Reddit response"})
	}

	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{"error": "Reddit returned error", "body": string(bodyBytes)})
	}

	var tokenResp map[string]interface{}
	if err := json.Unmarshal(bodyBytes, &tokenResp); err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to parse Reddit token response"})
	}

	return c.JSON(fiber.Map{
		"token":        tokenResp["access_token"],
		"refreshToken": tokenResp["refresh_token"], // optional
		"expiresIn":    tokenResp["expires_in"],
	})
}

// POST /api/reddit/feed
func RedditFeed(c *fiber.Ctx) error {
	var body RedditFeedRequest
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
		return c.Status(resp.StatusCode).JSON(fiber.Map{
			"error":  "Reddit returned error",
			"status": resp.StatusCode,
			"body":   string(bodyBytes),
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
