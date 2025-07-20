package sentiment

import (
	"log"
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/drankou/go-vader/vader"
)

var sa = vader.SentimentIntensityAnalyzer{}

func TestMain(m *testing.M) {
	if err := sa.Init("../data/vader_lexicon.txt", "../data/emoji_utf8_lexicon.txt"); err != nil {
		log.Fatal(err)
	}
	os.Exit(m.Run())
}

func TestComputeWordSentiments_TokenOutput_ReducedTextMatches(t *testing.T) {
	body := "Hello world\nthis is a long string\nwith line    breaks and strange    whitespace"
	res := ComputeWordSentiments(&sa, body)

	// recombine
	builder := strings.Builder{}
	for _, item := range res {
		builder.WriteString(item.Token)
	}
	if builder.String() != body {
		t.Errorf(
			"Failed to reduce output to be identical after tokenization. Wanted %s, got: %s\n",
			body, builder.String(),
		)
	}
}

func TestComputeWordSentiments_TokenUnits_SplitCorrectlyOnWhitespace(t *testing.T) {
	body := "This is a simple string"
	res := ComputeWordSentiments(&sa, body)
	expected := []TokenSentiment{
		{
			Token: "This ",
			Score: 0.0,
		},
		{
			Token: "is ",
			Score: 0.0,
		},
		{
			Token: "a ",
			Score: 0.0,
		},
		{
			Token: "simple ",
			Score: 0.0,
		},
		{
			Token: "string",
			Score: 0.0,
		},
	}

	if !reflect.DeepEqual(res, expected) {
		t.Errorf("Tokens did not match expected. Got %#v, expected: %#v", res, expected)
	}
}
