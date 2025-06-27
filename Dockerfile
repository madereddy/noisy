FROM cgr.dev/chainguard/python:latest-dev@sha256:ec4d7d778f4b3d535102e680ba343608e708bd08ec2cdff3b7fd909e8c38e5b1 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ae93505cca87c6ea679ef7b1c61ec33a86e89329067c059d54e8a585313098e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
