FROM cgr.dev/chainguard/python:latest-dev@sha256:6958806e6fbc6bb7fd5fd2727b4f6d750d9bb04b02ecff526a90a58d2da098fa AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e080491bb0eb05cc538160fe476f36c7b1ae4fde454ec173677a0e32cba89b26
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
