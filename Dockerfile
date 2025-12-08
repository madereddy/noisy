FROM cgr.dev/chainguard/python:latest-dev@sha256:d668d153281dbec86a6a16adbf1706cba57a5f892d7bdf03d4784e07572d558d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:255be8dd1d69d0a704d7e8c0b9883636116fc1a1fa929700c5fbbb236714419b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
