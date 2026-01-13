FROM cgr.dev/chainguard/python:latest-dev@sha256:b3a6903df91866d99a27d791bcc544d4c9d11ef029792dde8a89e7fbf175a444 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1873824295b959ab33a1491d78ff96bccd3aa82c058d5685341fe638e02e496c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
