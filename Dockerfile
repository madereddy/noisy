FROM cgr.dev/chainguard/python:latest-dev@sha256:4f38919abd322d122a8219a7b6147e419806c29ad3b269596288bf61a0a40867 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e61aa6065e00ae3449521ae86e3ed096a729e1fb9d2f40e9e4c8d342379c5f0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
