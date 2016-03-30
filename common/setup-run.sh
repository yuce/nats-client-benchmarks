set -e

if [ "$NATS_URL" == "" ]
then
    nats_url="nats://127.0.0.1:4222"    
else
    nats_url=$NATS_URL
fi

if [ "$MSG_COUNT" == "" ]
then
    msg_count="10000"
else
    msg_count=$MSG_COUNT
fi
