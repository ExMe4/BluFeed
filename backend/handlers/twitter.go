package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/ExMe4/BluFeed/backend/database"
	"github.com/gofiber/fiber/v2"
)

type TwitterTokenRequest struct {
	Code         string `json:"code"`
	CodeVerifier string `json:"code_verifier"`
	RedirectUri  string `json:"redirect_uri"`
	UserID       string `json:"user_id"`
}

type TwitterFeedRequest struct {
	Token string `json:"token"`
}

func TwitterToken(c *fiber.Ctx) error {
	var body TwitterTokenRequest
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid payload"})
	}

	form := url.Values{}
	form.Set("grant_type", "authorization_code")
	form.Set("code", body.Code)
	form.Set("redirect_uri", body.RedirectUri)
	form.Set("code_verifier", body.CodeVerifier)
	form.Set("client_id", os.Getenv("X_CLIENT_ID"))

	req, err := http.NewRequest("POST", "https://api.twitter.com/2/oauth2/token", strings.NewReader(form.Encode()))
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to create request"})
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Token exchange failed"})
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != 200 {
		return c.Status(resp.StatusCode).JSON(fiber.Map{"error": "Twitter error", "body": string(bodyBytes)})
	}

	var tokenResp map[string]interface{}
	json.Unmarshal(bodyBytes, &tokenResp)

	accessToken, ok := tokenResp["access_token"].(string)
	if !ok {
		return c.Status(500).JSON(fiber.Map{"error": "Invalid token response"})
	}

	_, err = database.DB.Exec(
		c.Context(),
		`INSERT INTO user_tokens (user_id, twitter_token)
		 VALUES ($1, $2)
		 ON CONFLICT (user_id) DO UPDATE SET twitter_token = EXCLUDED.twitter_token`,
		body.UserID,
		accessToken,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to save token to DB"})
	}

	return c.JSON(tokenResp)
}

func TwitterFeed(c *fiber.Ctx) error {
	var body TwitterFeedRequest
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid payload"})
	}

	req, _ := http.NewRequest("GET", "https://api.twitter.com/2/users/me/tweets", nil)
	req.Header.Set("Authorization", "Bearer "+body.Token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Request failed"})
	}
	defer resp.Body.Close()

	bodyBytes, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return c.Status(resp.StatusCode).JSON(fiber.Map{"error": "Twitter returned error", "body": string(bodyBytes)})
	}

	var jsonBody interface{}
	json.Unmarshal(bodyBytes, &jsonBody)

	return c.JSON(jsonBody)
}
