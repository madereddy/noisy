FROM cgr.dev/chainguard/python:latest-dev@sha256:523ee3e623cc2a1a8bb8b7a681afc70738a5f0967c1366288f0fbf214aa97938 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0ed9f745adb1df1131a46e89945bde7117eadde7b904c74188ec81df3f488c2b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
