FROM cgr.dev/chainguard/python:latest-dev@sha256:733aed1addc7d6d396ab862b608c9ec0701e240d6af4c70df3cf8622aecd1536 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:383c8b591d31dd66d36fc0a565a24c7ce7ed04df63114f0074489bc13a8dc925
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
