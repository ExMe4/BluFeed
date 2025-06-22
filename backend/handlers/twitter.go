package handlers

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"os"

	"github.com/gofiber/fiber/v2"
)

type TwitterTokenRequest struct {
	Code         string `json:"code"`
	CodeVerifier string `json:"code_verifier"`
	RedirectUri  string `json:"redirect_uri"`
}

type TwitterFeedRequest struct {
	Token string `json:"token"`
}

func TwitterToken(c *fiber.Ctx) error {
	var body TwitterTokenRequest
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid payload"})
	}

	data := map[string]string{
		"grant_type":    "authorization_code",
		"code":          body.Code,
		"redirect_uri":  body.RedirectUri,
		"code_verifier": body.CodeVerifier,
		"client_id":     os.Getenv("X_CLIENT_ID"),
	}

	jsonData, _ := json.Marshal(data)

	resp, err := http.Post("https://api.twitter.com/2/oauth2/token", "application/json", bytes.NewBuffer(jsonData))
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
