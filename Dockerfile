FROM cgr.dev/chainguard/python:latest-dev@sha256:0f8ac12416c82f402083739a1a6b12d89eb605c667664305976ae9543c72aac5 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2fc6f46589ffc4eaffdde315ddd9e76f7da9255eb117349023d8e4507a558770
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
