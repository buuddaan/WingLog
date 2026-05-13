#!/bin/sh
echo "$GOOGLE_CREDENTIALS_JSON" | base64 -d > /tmp/credentials.json
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/credentials.json
exec java -jar /app/app.jar
