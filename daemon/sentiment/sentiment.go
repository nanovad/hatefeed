package sentiment

import (
	"log"
	"strings"
	"unicode"

	"github.com/drankou/go-vader/vader"
)

type TokenSentiment struct {
	Token string  `json:"token"`
	Score float64 `json:"score"`
}

func SetupAnalyzer() vader.SentimentIntensityAnalyzer {
	sia := vader.SentimentIntensityAnalyzer{}
	err := sia.Init("./data/vader_lexicon.txt", "./data/emoji_utf8_lexicon.txt")
	if err != nil {
		log.Fatal(err)
	}

	return sia
}

func ComputeSentiment(analyzer *vader.SentimentIntensityAnalyzer, body string) float64 {
	return analyzer.PolarityScores(body)["compound"]
}

func ComputeWordSentiments(analyzer *vader.SentimentIntensityAnalyzer, body string) []TokenSentiment {
	var sentiments []TokenSentiment
	tokenBuilder := strings.Builder{}

	// stuffToken takes the token from the builder, runs VADER analysis on it, and
	// inserts it into the sentiments slice.
	stuffToken := func() {
		token := tokenBuilder.String()
		sentiments = append(sentiments, TokenSentiment{
			Token: token,
			Score: ComputeSentiment(analyzer, token),
		})
		tokenBuilder.Reset()
	}

	// Tokenize by whitespace, but leave the whitespace trailing the
	// non-whitespace substrings. This allows the client to rebuild the body
	// accurately while allowing us to run VADER analysis on each word
	// (it ignores whitespaces).
	lastWasSpace := false
	for _, r := range body {
		runeIsSpace := unicode.IsSpace(r)
		// If we were following whitespaces, but this current rune is not
		// whitespace, stuff everything up to this point.
		if !runeIsSpace && lastWasSpace {
			stuffToken()
		}
		lastWasSpace = runeIsSpace
		tokenBuilder.WriteRune(r)
	}
	// The last token we were accumulating still needs to be stuffed.
	stuffToken()

	return sentiments
}
