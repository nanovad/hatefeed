package client

type CommandMessageType int

const (
	COMMAND_MSG_TYPE_INTERVAL CommandMessageType = iota
	COMMAND_MSG_TYPE_THRESHOLD
	COMMAND_MSG_TYPE_FEED_MODE
	COMMAND_MSG_TYPE_UNKNOWN
)

type FeedMode int

const (
	FEED_MODE_THRESHOLD FeedMode = iota
	FEED_MODE_RATE
)

type ClientCommand interface {
	Type() CommandMessageType
	PackedParameters() any
}

type ClientCommandThreshold struct {
	Threshold float32
}

func (c ClientCommandThreshold) Type() CommandMessageType {
	return COMMAND_MSG_TYPE_INTERVAL
}
func (c ClientCommandThreshold) PackedParameters() any {
	return c.Threshold
}

type ClientCommandInterval struct {
	Interval uint32
}

func (c ClientCommandInterval) Type() CommandMessageType {
	return COMMAND_MSG_TYPE_INTERVAL
}
func (c ClientCommandInterval) PackedParameters() any {
	return c.Interval
}

type ClientCommandFeedMode struct {
	Mode FeedMode
}

func (c ClientCommandFeedMode) Type() CommandMessageType {
	return COMMAND_MSG_TYPE_FEED_MODE
}
func (c ClientCommandFeedMode) PackedParameters() any {
	return c.Mode
}
