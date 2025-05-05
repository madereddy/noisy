FROM cgr.dev/chainguard/python:latest-dev@sha256:39c4875d2c9edbd84f3a0ece8b91cd4b669859bdb44dcc007e71eb7d024dbb4c AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:46f25c4e4ff281fc374222a34cf1fdc88a0c7d36c6e9f3132ee1e005dd2f1442
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
