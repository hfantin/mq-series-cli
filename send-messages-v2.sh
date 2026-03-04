#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <queue_name> <number_of_messages>"
    exit 1
fi

queue_name=$1
qtd=$2

echo "Sending $qtd messages to $queue_name..."

# Use a named pipe (FIFO) for maximum performance
fifo="/tmp/mq_messages_$$"
mkfifo "$fifo"

# Writer process - generates messages
(
    for ((i=1; i<=qtd; i++)); do
        echo "Message $i to $queue_name"
        # Show progress every 10,000 messages
        if ((i % 10000 == 0)); then
            echo "Generated $i messages..." >&2
        fi
    done
) > "$fifo" &

# Reader process - sends to MQ
cat "$fifo" | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput "$queue_name" QM1

# Clean up
rm "$fifo"

echo "All $qtd messages sent to $queue_name!"