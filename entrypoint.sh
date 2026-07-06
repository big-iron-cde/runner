#!/bin/sh

set -e

# Extract org from URL
ORG_NAME=$(echo "$RUNNER_ORG" | awk -F/ '{print $NF}')

# Fetch the runner registration Token from GitHub API
RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer $GITHUB_PAT" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/$ORG_NAME/actions/runners/registration-token" | jq -r .token)

cd /home/runner/actions-runner

# only configure runner if not already configured
if [ ! -f .runner ]; then
    echo "Runner not configured, configuring now..."
    ./config.sh --url "$RUNNER_ORG" --token "$RUNNER_TOKEN"
else
    echo "Runner already configured, skipping config."
fi

# Start the runner in the background
./run.sh &
