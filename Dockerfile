FROM cgr.dev/chainguard/python:latest-dev@sha256:d3f9afd3ed35bb30563318d6b2e3182f7e6f0a2ece4e16897b4eb9ffccc7bbeb AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:46f25c4e4ff281fc374222a34cf1fdc88a0c7d36c6e9f3132ee1e005dd2f1442
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
