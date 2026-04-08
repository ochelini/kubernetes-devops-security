#!/bin/bash
set -eo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="bernardo"
JENKINS_TOKEN="11156e12b6e930ff153da0fec9273d9df0"

echo "=== Waiting for Jenkins to start ==="
until curl -s $JENKINS_URL/login > /dev/null; do
    echo "Jenkins not ready yet..."
    sleep 5
done

echo "Jenkins already initialized — skipping initial admin password step."

echo "=== Getting Jenkins crumb ==="
CRUMB=$(curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
    "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb')

echo "=== Creating API token ==="
TOKEN_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
    -H "Jenkins-Crumb:$CRUMB" \
    -X POST "$JENKINS_URL/user/$JENKINS_USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
    --data "newTokenName=installer")

API_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.data.tokenValue')

echo "Jenkins URL: $JENKINS_URL"
echo "Crumb: $CRUMB"
echo "API Token: $API_TOKEN"

echo "=== Installing plugins ==="
while read plugin; do
    echo "Installing plugin: $plugin"
    curl -s -X POST \
        -u "$JENKINS_USER:$API_TOKEN" \
        -H "Jenkins-Crumb:$CRUMB" \
        -H "Content-Type: text/xml" \
        --data "<jenkins><install plugin='${plugin}' /></jenkins>" \
        "$JENKINS_URL/pluginManager/installNecessaryPlugins"
done < plugins.txt

echo "=== Triggering Jenkins safe restart ==="
curl -s -X POST \
    -u "$JENKINS_USER:$API_TOKEN" \
    -H "Jenkins-Crumb:$CRUMB" \
    "$JENKINS_URL/safeRestart"

echo "=== Jenkins plugin installation complete ==="
