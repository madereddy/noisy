FROM cgr.dev/chainguard/python:latest-dev@sha256:b3a6903df91866d99a27d791bcc544d4c9d11ef029792dde8a89e7fbf175a444 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c61c2d11da44d85e79d8957bd1d21ba4b0313e96801b460bb3f44d256e5beb58
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
