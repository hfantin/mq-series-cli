#!/bin/bash

# Check if both arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <queue_name> <number_of_messages>"
    echo "Example: $0 DEV.QUEUE.1 100"
    echo "Example: $0 DEV.DEAD.LETTER.QUEUE 50"
    exit 1
fi

queue_name=$1
qtd=$2

# Optional: Validate that the second argument is a number
if ! [[ "$qtd" =~ ^[0-9]+$ ]]; then
    echo "Error: Number of messages must be a positive integer"
    exit 1
fi

echo "Sending $qtd messages to $queue_name..."
echo ""

for ((i=1; i<=qtd; i++)); do
    # Calculate progress percentage
    percent=$((i * 100 / qtd))
    
    # Create a simple progress bar
    bar=""
    for ((j=0; j<percent/2; j++)); do
        bar="${bar}█"
    done
    for ((j=percent/2; j<50; j++)); do
        bar="${bar}░"
    done
    
    # Show progress
    printf "\r[%s] %d/%d (%d%%) - Sending message %d" "$bar" "$i" "$qtd" "$percent" "$i"
    
    # Send the message
    echo "Message $i to $queue_name" | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput "$queue_name" QM1 > /dev/null
done

echo ""
echo ""
echo "✓ All $qtd messages sent successfully to $queue_name!"

# Show final queue depth
depth_output=$(docker exec -it ibm-mq-server su - mqm -c "echo 'DISPLAY QLOCAL($queue_name) CURDEPTH' | runmqsc QM1" 2>/dev/null)

if [[ $depth_output == *"AMQ8409I"* ]]; then
    depth=$(echo "$depth_output" | grep CURDEPTH | awk '{print $NF}')
    echo "📊 Current queue depth for $queue_name: $depth messages"
else
    echo "⚠️  Could not retrieve queue depth for $queue_name"
fi