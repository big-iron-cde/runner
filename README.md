# Big-Iron Runner

A containerized, self-hosted [GitHub Actions](https://docs.github.com/en/actions) runner built with Docker. Designed for the `big-iron-cde` organization, this runner supports hardware-in-the-loop workflows with privileged container access and serial device passthrough.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Automated runner setup** – Downloads and configures the latest GitHub Actions runner at image build time.
- **Dockerized workflow** – Runs inside a lightweight `debian:trixie-slim` container.
- **Hardware access** – Privileged mode with serial device passthrough (`/dev/ttyACM0`) for embedded and hardware-in-the-loop testing.
- **Built-in tooling** – Pre-installed Python 3, Git, `jq`, and the `romulan` utility from `big-iron-cde/romulan`.
- **CI/CD ready** – Automated image builds and publishes to [GitHub Container Registry (GHCR)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) via GitHub Actions.

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- A GitHub organization with [self-hosted runner](https://docs.github.com/en/actions/hosting-your-own-runners) support
- A GitHub personal access token (PAT) with `admin:org` scope (for runner registration)

---

## Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/big-iron-cde/runner.git
   cd runner
   ```

2. **Configure environment variables**

   Copy the example environment file and fill in your values:

   ```bash
   cp .env .env.local
   # Edit .env.local with your token and org
   ```

3. **Build and run**

   ```bash
   docker compose up --build
   ```

The runner will register itself with your GitHub organization and begin accepting jobs.

---

## Configuration

All runtime configuration is handled via environment variables. The table below lists the required and optional variables used by the container and entrypoint script.

| Variable | Required | Description |
|---|---|---|
| `RUNNER_IMAGE` | Yes | Docker image name/tag for the runner service. |
| `GITHUB_ORG` | Yes | GitHub organization name (e.g., `big-iron-cde`). |
| `RUNNER_TOKEN` | Yes | GitHub personal access token with `admin:org` scope used to generate the runner registration token. |

These values are consumed by `docker-compose.yml` and `entrypoint.sh`.

### Docker Compose

The `docker-compose.yml` defines a single `runner` service:

- **Privileged mode** enabled for full system access.
- **Device mapping** exposes `/dev/ttyACM0` inside the container for serial hardware communication.
- **Environment** sourced from your `.env` file.

---

## Usage

### Local Development

```bash
# Build the image locally
docker build -t runner:latest .

# Run manually with env vars
docker run --rm -it \
  -e RUNNER_ORG=https://github.com/your-org \
  -e RUNNER_TOKEN=ghp_xxxxxxxxxxxx \
  --privileged \
  --device /dev/ttyACM0 \
  runner:latest
```

### Production Deployment

Use the pre-built image from GHCR:

```yaml
services:
  runner:
    image: ghcr.io/big-iron-cde/runner:latest
    environment:
      RUNNER_ORG: https://github.com/${GITHUB_ORG}
      RUNNER_TOKEN: ${RUNNER_TOKEN}
    privileged: true
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
```

---

## GitHub Actions Workflow

The repository includes a CI workflow (`.github/workflows/build-ghcr.yml`) that:

1. Builds the Docker image on every SemVer tag push (`*.*.*`).
2. Pushes the image to GHCR with both `latest` and tag-based labels.
3. Creates a GitHub Release with auto-generated release notes.

Trigger a new release by pushing a tag:

```bash
git tag 1.0.0
git push origin 1.0.0
```

---

## Contributing

Contributions are welcome! Please open an issue or pull request if you have improvements, bug fixes, or new features to propose.

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## License

This project is licensed under the [MIT License](./LICENSE).
