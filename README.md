### Disclaimer  
This app neither filters out nor censors any specific language or links. It is
often NSFW, and likely contains copius amounts of offensive and derogatory
language. View at your own risk.

See [Methodology](#methodology) for a more detailed explanation of what makes it
into the Hatefeed.

# What is this?
This is the [Hatefeed](https://hatefeed.ing) - a chronological, real-time stream
of the Bluesky post firehose, passed through a sentiment analyzer, then filtered
further to display posts containing a very negative sentiment.

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
uses an unaffiliated Rust port of this algorithm.

The body of each Bluesky post is passed through the VADER algorithm in real
time. If the score is positive, it is discarded. If the score is negative, it is
passed along to a per-client "stack" of posts. This stack retains 128 posts with
the most negative score. Posts are retrieved from the stack and sent to the
client depending on the feed mode.

Currently, client feed modes of "threshold" and "interval" are implemented.
Threshold mode sends posts to the client if the score is more negative than some
selected value. Interval mode sends posts to the client at a configurable
interval, such as every 5 seconds. Post details, such as body, author, and post
ID, are sent to the connected client along with the VADER sentiment score. The
post is displayed in a familiar card format, with author, username, body text,
and share options. The VADER sentiment is displayed in the right edge of the
post card.

In addition to the whole-post score, each individual word in the post is scored,
providing a hint (though it's likely not entirely accurate) as to why the post
was scored the way it was. This option is enabled in the client by default, and
can be disabled by toggling _Color words by individual sentiment_.

If you're curious about the nitty-gritty, then...

# Technical Details
Hatefeed is composed of 2 systems: a user interface (see `ui`), written in
Flutter, and a sentiment analysis daemon (see `daemon`) written in Rust and
Dockerized. Posts are provided to the daemon in real time, uncompressed, via the
[Bluesky Jetstream](https://github.com/bluesky-social/jetstream) service over
websockets, then from the daemon to the client via more websockets. The client
then handles presentation of the posts as they arrive.

Sentiment analysis is performed in the daemon by the
[vader-sentimental](https://github.com/bosun-ai/vader-sentimental) library.

The web UI and daemon are both hosted on a Linux server with an nginx reverse
proxy in front.

# License
Hatefeed is licensed under an MIT license. See [LICENSE.md](LICENSE.md).

# Citations
> Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for Sentiment Analysis of Social Media Text. Eighth International Conference on Weblogs and Social Media (ICWSM-14). Ann Arbor, MI, June 2014.
