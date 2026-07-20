#!/bin/bash

set -euo pipefail

# Extract org from URL
ORG_NAME=$(echo "$RUNNER_ORG" | awk -F/ '{print $NF}')

# GitHub API hosts
GITHUB_HOST=${GITHUB_HOST:-github.com}
GITHUB_API_HOST=${GITHUB_API_HOST:-api.github.com}

# RUNNER_TOKEN from the environment is the PAT; preserve it separately.
ACCESS_TOKEN="${RUNNER_TOKEN}"

# Fetch a short-lived runner registration token
REGISTRATION_TOKEN=$(curl -fsSL -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://${GITHUB_API_HOST}/orgs/${ORG_NAME}/actions/runners/registration-token" | jq -r .token)

if [[ -z "${REGISTRATION_TOKEN}" || "${REGISTRATION_TOKEN}" == "null" ]]; then
    echo "ERROR: failed to fetch runner registration token" >&2
    exit 1
fi

cd /home/runner/actions-runner

# Defaults
_DISABLE_AUTOMATIC_DEREGISTRATION=${DISABLE_AUTOMATIC_DEREGISTRATION:-false}
_DEREGISTERED=false
_RUNNER_PID=""

configure_runner() {
    echo "Configuring runner ${RUNNER_NAME} for ${RUNNER_ORG}"

    ./config.sh \
        --url "${RUNNER_ORG}" \
        --token "${REGISTRATION_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --unattended \
        --replace
}

fetch_remove_token() {
    local token
    token=$(curl -fsSL -X POST \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        "https://${GITHUB_API_HOST}/orgs/${ORG_NAME}/actions/runners/remove-token" | jq -r .token)

    if [[ -z "${token}" || "${token}" == "null" ]]; then
        echo "ERROR: failed to fetch runner remove token" >&2
        exit 1
    fi
    echo "${token}"
}

deregister_runner() {
    local CAUGHT="${1:-EXIT}"
    echo "Caught ${CAUGHT} - deregistering runner"

    if [[ "${_DEREGISTERED}" == "true" ]]; then
        return 0
    fi
    _DEREGISTERED=true

    local REMOVE_TOKEN
    REMOVE_TOKEN=$(fetch_remove_token)

    ./config.sh remove --token "${REMOVE_TOKEN}"

    # Remove the local runner state file
    [[ -f ".runner" ]] && rm -f ".runner"
}

cleanup_and_exit() {
    local CAUGHT="${1:-EXIT}"

    # Disable traps to prevent re-entry
    trap - EXIT SIGTERM TERM SIGINT INT SIGQUIT QUIT

    echo "Caught ${CAUGHT} - cleaning up"

    # Forward SIGTERM to the actual runner listener and wait for it to finish
    if [[ -n "${_RUNNER_PID}" ]] && kill -0 "${_RUNNER_PID}" 2>/dev/null; then
        echo "Stopping runner process ${_RUNNER_PID}"
        kill -TERM "${_RUNNER_PID}"
        wait "${_RUNNER_PID}" || true
    fi

    if [[ ${_DISABLE_AUTOMATIC_DEREGISTRATION} == "false" ]]; then
        deregister_runner "${CAUGHT}"
    fi

    case "${CAUGHT}" in
        EXIT)
            exit "${LAST_EXIT_CODE:-0}"
            ;;
        SIGTERM|TERM)
            exit 0
            ;;
        SIGINT|INT|SIGQUIT|QUIT)
            exit 130
            ;;
        *)
            exit 1
            ;;
    esac
}

# Only configure runner if not already configured
if [ ! -f .runner ]; then
    echo "Runner not configured, configuring now..."
    configure_runner
else
    echo "Runner already configured, skipping config."
fi

# Register cleanup handlers
if [[ ${_DISABLE_AUTOMATIC_DEREGISTRATION} == "false" ]]; then
    trap 'LAST_EXIT_CODE=$?; cleanup_and_exit EXIT' EXIT
    trap 'cleanup_and_exit SIGTERM' SIGTERM TERM
    trap 'cleanup_and_exit SIGINT' SIGINT INT
    trap 'cleanup_and_exit SIGQUIT' SIGQUIT QUIT
fi

# Default arguments if the Dockerfile does not supply a CMD
if [[ $# -eq 0 ]]; then
    set -- run --startuptype service
fi

# Run the listener directly so we have its real PID for signal forwarding
./bin/Runner.Listener "$@" &
_RUNNER_PID=$!

# Wait for the runner process. When a signal arrives, the trap will interrupt wait.
wait "${_RUNNER_PID}"
