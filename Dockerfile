FROM cgr.dev/chainguard/python:latest-dev@sha256:4b667393d6f57c20aaf7d6baf4b33c4cf3923ab8ef5a64b532cffaf114d211c6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cfba883e4a91151c0ca0c18ec142d61eaee55d64bd489f13a0a4274dff425d93
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]