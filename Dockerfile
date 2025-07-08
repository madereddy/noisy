FROM cgr.dev/chainguard/python:latest-dev@sha256:26eaa7a1a5baafb4c00bee9f1fbd744419290facf2ff2d6e1021c7b63a5b471d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e0dbf1d2dd8116bc4c5b9066281b1939777eba163e7e7801d3d34fc8ebe5bedb
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
