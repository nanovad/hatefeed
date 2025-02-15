package client

import (
	"fmt"
	"strconv"
)

const MSG_HANDSHAKE_CLIENT_READY = "READY"
const MSG_HANDSHAKE_SERVER_REPLY = "OKAYLESGO"

func IdentifyMessage(msg string) CommandMessageType {
	if msg[:8] == "INTERVAL" {
		return COMMAND_MSG_TYPE_INTERVAL
	} else if msg[:9] == "THRESHOLD" {
		return COMMAND_MSG_TYPE_THRESHOLD
	} else if msg[:4] == "MODE" {
		return COMMAND_MSG_TYPE_FEED_MODE
	}
	return COMMAND_MSG_TYPE_UNKNOWN
}

func ParseMessage(msg string) (cc ClientCommand, err error) {
	msgType := IdentifyMessage(msg)

	if msgType == COMMAND_MSG_TYPE_INTERVAL {
		intervalStr := msg[9:]
		interval, err := strconv.ParseInt(intervalStr, 10, 32)

		// Ignore parse errors. It's probably a malformed
		// message from the client and should have no effect.
		if err == nil {
			return ClientCommandInterval{uint32(interval)}, nil
		}
	} else if msgType == COMMAND_MSG_TYPE_THRESHOLD {
		thresholdStr := msg[10:]
		threshold, err := strconv.ParseFloat(thresholdStr, 32)
		if err == nil {
			return ClientCommandThreshold{float32(threshold)}, nil
		}
	} else if msgType == COMMAND_MSG_TYPE_FEED_MODE {
		modeStr := msg[5:]

		var mode FeedMode
		switch modeStr {
		case "THRESHOLD":
			mode = FEED_MODE_THRESHOLD
		case "RATE":
			mode = FEED_MODE_RATE
		default:
			return nil, fmt.Errorf("invalid feed mode %s", modeStr)
		}

		return ClientCommandFeedMode{FeedMode(mode)}, nil
	}

	return nil, fmt.Errorf("error parsing message %s", msg)
}
