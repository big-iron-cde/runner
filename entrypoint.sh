#!/bin/sh

set -e

# Extract org from URL
ORG_NAME=$(echo "$RUNNER_ORG" | awk -F/ '{print $NF}')

# Fetch the runner registration token from GitHub API
RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: Bearer $RUNNER_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/$ORG_NAME/actions/runners/registration-token" | jq -r .token)

cd /home/runner/actions-runner

# Set default value for _DISABLE_AUTOMATIC_DEREGISTRATION and _DEREGISTERED
_DISABLE_AUTOMATIC_DEREGISTRATION=${DISABLE_AUTOMATIC_DEREGISTRATION:-false}
_DEREGISTERED=false

configure_runner() {
  ARGS=()
    echo "Obtaining the token of the runner"
    #_TOKEN=$(ACCESS_TOKEN="${ACCESS_TOKEN}" bash /token.sh)
    #RUNNER_TOKEN=$(echo "${_TOKEN}" | jq -r .token)
  fi

  ./config.sh \
      --url "${RUNNER_ORG}" \
      --token "${RUNNER_TOKEN}" \
      --name "${RUNNER_NAME}" \
      --unattended \
      --replace \
      "${ARGS[@]}"

}

trap_with_arg() {
    func="$1" ; shift
    for sig ; do
        # shellcheck disable=SC2064
        trap "$func $sig" "$sig"
    done
}

deregister_runner() {
  local CAUGHT="${1:-EXIT}"
  echo "Caught ${CAUGHT} - Deregistering runner"

  if [[ "${_DEREGISTERED}" == "true" ]]; then
    return
  fi
  _DEREGISTERED=true

  ./config.sh remove --token "${RUNNER_TOKEN}"
  [[ -f "/actions-runner/.runner" ]] && rm -f /actions-runner/.runner

  if [[ "${CAUGHT}" != "EXIT" ]]; then
    exit 1
  else
    # For EXIT trap, preserve the original exit code
    exit "${LAST_EXIT_CODE:-0}"
  fi
}

# only configure runner if not already configured
if [ ! -f .runner ]; then
    echo "Runner not configured, configuring now..."
    configure_runner
else
    echo "Runner already configured, skipping config."
fi

# Deregister runner on exit or termination signals
if [[ ${_DISABLE_AUTOMATIC_DEREGISTRATION} == "false" ]]; then
    trap 'LAST_EXIT_CODE=$?; deregister_runner EXIT' EXIT
    trap_with_arg deregister_runner SIGINT SIGQUIT SIGTERM INT TERM QUIT
fi

# Start the runner in the background
./run.sh
