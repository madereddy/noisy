FROM cgr.dev/chainguard/python:latest-dev@sha256:c7afe78f15c543c9936151640ce819e4d6cd2cf0f027ac5749d3cda369079675 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b0feb5ef76e7306fe54d6a472053a3dc929e19a5f7d5b10dfd606d2f7104029d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]