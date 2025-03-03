package profile

import (
	"encoding/json"
	"net/http"
)

type BskyProfile struct {
	Did         string `json:"did"`
	Handle      string `json:"handle"`
	DisplayName string `json:"displayName"`
}

func resolveBskyProfile(did string, client *http.Client) (prof *BskyProfile, err error) {
	r, err := client.Get("https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=" + did)
	if err != nil {
		return nil, err
	}
	defer r.Body.Close()

	var profile BskyProfile
	err = json.NewDecoder(r.Body).Decode(&profile)
	if err != nil {
		return nil, err
	}

	// Use handle as display name if there is no display name set
	if profile.DisplayName == "" {
		profile.DisplayName = profile.Handle
	}

	return &profile, nil
}
