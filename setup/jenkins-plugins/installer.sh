#!/bin/bash
set -eo pipefail

JENKINS_URL="http://localhost:8080"

echo "=== Waiting for Jenkins to start ==="
until curl -s $JENKINS_URL/login > /dev/null; do
    echo "Jenkins not ready yet..."
    sleep 5
done

echo "=== Reading initial admin password ==="
ADMIN_PASS=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo "=== Getting Jenkins crumb ==="
CRUMB=$(curl -s -u "admin:${ADMIN_PASS}" "$JENKINS_URL/crumbIssuer/api/json" | jq -r .crumb)

echo "=== Creating API token ==="
TOKEN=$(curl -s -X POST \
    -u "admin:${ADMIN_PASS}" \
    -H "Jenkins-Crumb:${CRUMB}" \
    -H "Content-Type: application/json" \
    -d '{"newTokenName": "automation-token"}' \
    "$JENKINS_URL/user/admin/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
    | jq -r .data.tokenValue)

echo "Jenkins URL: $JENKINS_URL"
echo "Crumb: $CRUMB"
echo "API Token: $TOKEN"

echo "=== Installing plugins ==="
while read plugin; do
    echo "Installing plugin: $plugin"
    curl -s -X POST \
        -u "admin:${TOKEN}" \
        -H "Jenkins-Crumb:${CRUMB}" \
        -H "Content-Type: text/xml" \
        --data "<jenkins><install plugin='${plugin}' /></jenkins>" \
        "$JENKINS_URL/pluginManager/installNecessaryPlugins"
done < plugins.txt

echo "=== Triggering Jenkins safe restart ==="
curl -s -X POST \
    -u "admin:${TOKEN}" \
    -H "Jenkins-Crumb:${CRUMB}" \
    "$JENKINS_URL/safeRestart"

echo "=== Jenkins plugin installation complete ==="
