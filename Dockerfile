FROM cgr.dev/chainguard/python:latest-dev@sha256:6c8b993b7f1024b286e15c77d73a6681eb56f766ddb09f3ee0d90f3b5152ba49 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ca9d5a51ade3c4d541e73be4a7357d45421f13c431c2a74c8202c116261326f9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
