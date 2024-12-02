package sentiment

import (
	"log"

	"github.com/drankou/go-vader/vader"
)

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
