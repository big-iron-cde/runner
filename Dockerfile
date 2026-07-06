FROM  debian:trixie-slim

RUN   useradd -ms /bin/bash runner

# Runner Setup

RUN   mkdir -p /home/runner/actions-runner
RUN   cd /home/runner/actions-runner && \
      curl -o actions-runner-linux-x64-2.330.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.330.0/actions-runner-linux-x64-2.330.0.tar.gz && \
      tar xzf ./actions-runner-linux-x64-2.330.0.tar.gz

ADD entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

RUN chown runner:runner /home/runner -R
RUN chmod o+rws /home/runner -R

USER runner

ENTRYPOINT ["/home/runner/entrypoint.sh"]
