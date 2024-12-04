### Disclaimer  
This app neither filters out nor censors any specific language or links. It is
often NSFW, and likely contains copius amounts of offensive and derogatory
language. View at your own risk.

See [Methodology](#methodology) for a more detailed explanation of what makes it into the
Hatefeed.

# What is this?
This is the [Hatefeed](https://hatefeed.nanovad.com) - a chronological,
real-time stream of the Bluesky post firehose, passed through a sentiment
analyzer, then filtered to display only the posts containing a very negative
sentiment.

In essence, it's the worst posts you might run across, surfaced for your
enjoyment in real time.

Typically, the first question I'm asked when people hear about the Hatefeed,
is...

# Why?
Why not? It's just as easy to filter for very positive sentiment instead, and
make a Lovefeed, right? Why not bring more positivity to the world?

The problem is that spam bots and 18+ accounts typically use language that the
sentiment analyzer deems positive; filtering to very positive messages usually
gets you either benign messages like "I love your dress!" or erotic roleplay or
sex solicitation. For the sake of variety, it's better to show
negative-sentiment messages.

I have plans to add a user-adjustable filter that would allow you to select, for
example, only positive posts; however for now, the filter is not configurable
unless you modify the source code.

The matter of what posts are considered negative brings us to...

# Methodology
Hatefeed uses the VADER sentiment analysis algorithm and lexicon by C.J. Hutto
and E.E. Gilbert. An official citation can be found in the
[Citations section](#citations). The reference implementation for VADER can be
found at https://github.com/cjhutto/vaderSentiment, which includes a README
explaining how a sentiment score is reached for a given body of text. Hatefeed
uses an unaffiliated Go port of this algorithm.

For the Hatefeed's purposes, it passes the body of each post through the VADER
algorithm, then filters by the compound sentiment score. If the score is more
negative than a specific threshold (currently `<= -0.75`) the post details,
such as body, author, and post ID, are forwarded to any connected clients along
with its VADER sentiment score. The client then uses that sentiment score to
visualize the post and display it to you.

If you're curious about the nitty-gritty, then...

# Technical Details
Hatefeed is composed of 2 systems: a user interface (see `ui`), written in
Flutter, and a sentiment analysis daemon (see `daemon`) written in Go. Posts are
provided to the daemon in real time, uncompressed, via the
[Bluesky Jetstream](https://github.com/bluesky-social/jetstream) service over
websockets, then from the daemon to the client via more websockets. The client
then handles presentation of the posts as they arrive.

Sentiment analysis is performed in the daemon by
[@drankou](https://github.com/drankou)'s
[go-vader](https://github.com/drankou/go-vader) library.

The web UI and daemon are both hosted on a Linux server with an nginx reverse
proxy in front.

# License
Hatefeed is licensed under an MIT license. See [LICENSE.md](LICENSE.md).

# Citations
> Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text. Eighth International Conference on Weblogs and Social Media (ICWSM-14). Ann Arbor, MI, June 2014.
