FROM cgr.dev/chainguard/python:latest-dev@sha256:0046ca9773d0781e3409e8863a67450f9d6eec78debecd2437af0dca3be91fa9 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e5cd2fd57ba08b39e49ed6a02d2192a11247600b7f2d4d8b79911d9607b789bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
