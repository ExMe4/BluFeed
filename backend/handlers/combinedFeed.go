// handlers/combined_feed.go
package handlers

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type CombinedFeedRequest struct {
	RedditToken  string `json:"reddit_token"`
	TwitterToken string `json:"twitter_token"`
}

func CombinedFeed(c *fiber.Ctx) error {
	var body CombinedFeedRequest
	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid request body"})
	}

	var combinedPosts []map[string]interface{}

	// --- Fetch Reddit Feed ---
	if body.RedditToken != "" {
		redditPayload := map[string]string{"token": body.RedditToken}
		jsonData, _ := json.Marshal(redditPayload)

		resp, err := http.Post("http://localhost:3000/api/reddit/feed", "application/json", bytes.NewBuffer(jsonData))
		if err == nil && resp.StatusCode == http.StatusOK {
			defer resp.Body.Close()
			data, _ := io.ReadAll(resp.Body)

			var redditResponse map[string]interface{}
			_ = json.Unmarshal(data, &redditResponse)

			// Extract posts
			if posts, ok := redditResponse["data"].(map[string]interface{})["children"].([]interface{}); ok {
				for _, p := range posts {
					if postData, ok := p.(map[string]interface{})["data"].(map[string]interface{}); ok {
						combinedPosts = append(combinedPosts, map[string]interface{}{
							"source":    "reddit",
							"title":     postData["title"],
							"subreddit": postData["subreddit"],
						})
					}
				}
			}
		}
	}

	// --- Fetch Twitter Feed ---
	if body.TwitterToken != "" {
		twitterPayload := map[string]string{"token": body.TwitterToken}
		jsonData, _ := json.Marshal(twitterPayload)

		resp, err := http.Post("http://localhost:3000/api/twitter/feed", "application/json", bytes.NewBuffer(jsonData))
		if err == nil && resp.StatusCode == http.StatusOK {
			defer resp.Body.Close()
			data, _ := io.ReadAll(resp.Body)

			var twitterResponse map[string]interface{}
			_ = json.Unmarshal(data, &twitterResponse)

			// Parse tweets
			if tweets, ok := twitterResponse["data"].([]interface{}); ok {
				for _, t := range tweets {
					if tweet, ok := t.(map[string]interface{}); ok {
						combinedPosts = append(combinedPosts, map[string]interface{}{
							"source":   "twitter",
							"text":     tweet["text"],
							"username": "user", // todo replace with actual username if available
						})
					}
				}
			}
		}
	}

	if body.RedditToken == "" && body.TwitterToken == "" {
		log.Println("No tokens provided to combined feed.")
		return c.Status(400).JSON(fiber.Map{"error": "No tokens provided"})
	}

	return c.JSON(fiber.Map{"data": combinedPosts})
}
