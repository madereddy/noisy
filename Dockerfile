FROM cgr.dev/chainguard/python:latest-dev@sha256:628d2c89b7f123ff7352b987be4140c947904a5d940d9c1a80b7afce00db9d66 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b14c51dcd50db3f476eba232515c9e343058a546c766873991af1e4726f8dbaf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
