# Use minimal *nix distribuion

FROM  debian:trixie-slim

# Create runner user

RUN   useradd -ms /bin/bash runner

# Install dependencies

RUN   apt-get update && apt-get install -y \
      curl \
      jq \
      git \
      python3 \
      python3-pip \
      python3-venv \
      python-is-python3

# Runner Setup (acquires latest version available at image build)

RUN   mkdir -p /home/runner/actions-runner
RUN   cd /home/runner/actions-runner && \
      RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') && \
      curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
      tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy the entrypoint script into the container

ADD entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# Change ownership of relevant directories

RUN chown runner:runner /home/runner -R
RUN chmod o+rws /home/runner -R

# TODO: Install romulan from PyPi
# BUT: Until then, we clone it
RUN git clone https://github.com/big-iron-cde/romulan.git
RUN cd romulan && python -m pip install . --break-system-packages

# Set the runner user as user running workloads

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
