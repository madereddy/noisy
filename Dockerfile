FROM cgr.dev/chainguard/python:latest-dev@sha256:4968705def11dd6a55b24975611b3e52d502faea31711fae6e297c3741c57a99 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cfba883e4a91151c0ca0c18ec142d61eaee55d64bd489f13a0a4274dff425d93
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]