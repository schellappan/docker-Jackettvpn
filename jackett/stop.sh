#! /bin/bash

# If jackett-pre-stop.sh exists, run it
if [[ -x /scripts/jackett-pre-stop.sh ]]
then
    echo "Executing /scripts/jackett-pre-stop.sh"
    /scripts/jackett-pre-stop.sh "$@"
    echo "/scripts/jackett-pre-stop.sh returned $?"
fi

echo "Sending kill signal to jackett daemon"
PID=$(pidof jackett)
kill "$PID"

# Give jackett-daemon some time to shut down
JACKETT_TIMEOUT_SEC=${JACKETT_TIMEOUT_SEC:-5}
for i in $(seq "$JACKETT_TIMEOUT_SEC")
do
    sleep 1
    [[ -z "$(pidof jackett)" ]] && break
    [[ $i == 1 ]] && echo "Waiting ${JACKETT_TIMEOUT_SEC}s for jackett daemon to die"
done

# Check whether jackett-daemon is still running
if [[ -z "$(pidof jackett)" ]]
then
    echo "Successfuly closed jackett daemon"
else
    echo "Sending kill signal (SIGKILL) to jackett daemon"
    kill -9 "$PID"
fi

# If jackett-post-stop.sh exists, run it
if [[ -x /scripts/jackett-post-stop.sh ]]
then
    echo "Executing /scripts/jackett-post-stop.sh"
    /scripts/jackett-post-stop.sh "$@"
    echo "/scripts/jackett-post-stop.sh returned $?"
fi
