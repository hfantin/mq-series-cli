#!/bin/bash

# Ultra-fast parallel MQ message sender
# Splits into multiple parallel streams for maximum throughput

if [ $# -lt 2 ]; then
    echo "Usage: $0 <queue_name> <number_of_messages> [parallel_streams]"
    echo "Example: $0 DEV.QUEUE.1 100000 4"
    exit 1
fi

queue_name=$1
qtd=$2
parallel=${3:-2}  # Default to 2 parallel streams

echo "🚀 Sending $qtd messages to $queue_name using $parallel parallel streams..."

# Create temporary directory for message chunks
tmp_dir=$(mktemp -d)
chunk_size=$((qtd / parallel))

# Function to send a chunk of messages
send_chunk() {
    local start=$1
    local end=$2
    local stream=$3
    
    {
        for ((i=start; i<=end; i++)); do
            echo "Message $i"
        done
    } | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput "$queue_name" QM1 > /dev/null 2>&1
    
    echo "Stream $stream completed" >&2
}

# Start parallel processes
start_time=$(date +%s)

for ((s=0; s<parallel; s++)); do
    start=$((s * chunk_size + 1))
    end=$(( (s + 1) * chunk_size ))
    if [ $s -eq $((parallel - 1)) ]; then
        end=$qtd  # Last chunk gets any remaining messages
    fi
    
    send_chunk $start $end $s &
    pids[$s]=$!
done

# Wait for all streams to complete
for pid in ${pids[*]}; do
    wait $pid
done

end_time=$(date +%s)
elapsed=$((end_time - start_time))

# Clean up
rm -rf "$tmp_dir"

echo "✅ All $qtd messages sent in ${elapsed} seconds!"
echo "📊 Rate: $((qtd / elapsed)) messages/second"