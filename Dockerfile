FROM cgr.dev/chainguard/python:latest-dev@sha256:2a649c948b4bb7a5950845a4adadbf98032b68e4544ead60472ba52f3c7365fb AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:255be8dd1d69d0a704d7e8c0b9883636116fc1a1fa929700c5fbbb236714419b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
