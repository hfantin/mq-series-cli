# MQ Console
- http://localhost:9443/ibmmq/console/


## how to solve permission errors

```bash 
# Stop and remove the container
docker-compose down -v

# Create the data directory if it doesn't exist
mkdir -p ./mq-data

# Set ownership to match the container user (UID 1001)
# On Linux:
sudo chown -R 1001:1001 ./mq-data

# On macOS (if sudo doesn't work, try:)
# sudo chown -R 1001:1001 ./mq-data
# Or if you get "illegal user name" error, use:
# docker run --rm -v $(pwd)/mq-data:/tmp alpine chown -R 1001:1001 /tmp

# Start the container
docker-compose up -d
```


### put messages in a queue 

> echo "Test message from command line" | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput QE.LOCAL.TEST QM1

### put a message from server 2 on server 1

> echo "Test message from command line" | docker exec -i ibm-mq-server-outro /opt/mqm/samp/bin/amqsputc QE.LOCAL.TEST QM1

# Generate and send in one pipeline
> seq 1 100 | while read num; do echo "Batch message $num"; done | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput QE.LOCAL.TEST QM1

# Generate 100 lines using a here document
```
(
  for i in {1..100}; do
    echo "Message $i sent at $(date)"
  done
) | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput DEV.QUEUE.1 QM1
```

# Progress Indicator
```
for i in {1..100000}; do
  echo "Sending message $i of 100000"
  echo "Message $i" | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput DEV.QUEUE.1 QM1 > /dev/null
done
echo "All 100000 messages sent!"
```

# send one message
> echo "test" | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput' QE.LOCAL.TEST QM1


# Add to your .bashrc or .zshrc
> alias mqput='seq 1 $1 | while read i; do echo "Message $i"; done | docker exec -i ibm-mq-server /opt/mqm/samp/bin/amqsput'

# Use it like this:
> mqput QE.LOCAL.TEST 1000

# Get all messages (this will display them all)
> docker exec -it ibm-mq-server /opt/mqm/samp/bin/amqsget QE.LOCAL.TEST QM1

# Check queue depth
> docker exec -it ibm-mq-server su - mqm -c "echo 'DISPLAY QLOCAL(QE.LOCAL.TEST) CURDEPTH' | runmqsc QM1"
