package profile

import (
	"net/http"
	"sync"
	"time"

	"github.com/hashicorp/golang-lru/v2/expirable"
)

type ProfileCache struct {
	cache      *expirable.LRU[string, *BskyProfile]
	httpClient http.Client
}

var profileCache *ProfileCache
var once sync.Once

func GetProfileCache() *ProfileCache {
	once.Do(func() {
		profileCache = NewProfileCache()
	})
	return profileCache
}

func NewProfileCache() *ProfileCache {
	return &ProfileCache{
		cache: expirable.NewLRU[string, *BskyProfile](100000, nil, 3*time.Hour),
		httpClient: http.Client{
			Timeout: 500 * time.Millisecond,
		},
	}
}

func (c *ProfileCache) ResolveProfile(did string) (profile *BskyProfile, err error) {
	// Try to hit the cache first, return the profile if we have one unexpired
	v, ok := c.cache.Get(did)
	if ok {
		return v, nil
	}

	// Otherwise go through the trouble of fetching it
	profile, err = resolveBskyProfile(did, &c.httpClient)
	if err != nil {
		return nil, err
	}

	// Cache it for next time
	c.cache.Add(did, profile)
	return profile, nil
}
