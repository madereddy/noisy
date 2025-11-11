FROM cgr.dev/chainguard/python:latest-dev@sha256:66ad90451e4b930d12fcf5cdf7d6a0cfdc030c4ff0f3cab4065a4a93a54b2d72 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:695359b1e5130bd27e8dab298c8c51c1fb4dc3023fa91eb895ef8b2696211328
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
