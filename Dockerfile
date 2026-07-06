FROM  debian:trixie-slim

RUN   useradd -ms /bin/bash runner

RUN   apt-get update && apt-get install -y \
      curl \
      jq

# Runner Setup

RUN   mkdir -p /home/runner/actions-runner
RUN   cd /home/runner/actions-runner && \
      RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') && \
      curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
      tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

ADD entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

RUN chown runner:runner /home/runner -R
RUN chmod o+rws /home/runner -R

# TODO: Install romulan from PyPi

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
