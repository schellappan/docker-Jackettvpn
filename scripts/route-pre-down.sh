#!/bin/bash
# redirect stdout/stderr to a file
#exec &>>route-pre-down.log

#Print Date
NOW=$(date +"%Y-%m-%d %T")

echo "${NOW}: route-pre-down script: Start "

echo "Sending exit signal to Jackett."
JACKETT_PASSWD_FILE=/config/jackett-credentials.txt
jackett_username=$(head -1 ${JACKETT_PASSWD_FILE})
jackett_passwd=$(tail -1 ${JACKETT_PASSWD_FILE})
jackett_settings_file=${JACKETT_HOME}/settings.json

# Check if jackett remote is set up with authentication
auth_enabled=$(grep 'rpc-authentication-required\"' "$jackett_settings_file" \
                   | grep -oE 'true|false')

if [[ "true" = "$auth_enabled" ]]
  then
  echo "jackett auth required"
  myauth="--auth $jackett_username:$jackett_passwd"
else
    echo "jackett auth not required"
    myauth=""
fi

jackett-remote $myauth --exit &

wait

echo "route-pre-down script: Done"



