FROM cgr.dev/chainguard/python:latest-dev@sha256:7a8a948a5a68092868c7e67520c6252a0dcdecd682fd31251cbc9807d54d52ad AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:172a288df4aeb380077d5efabdbda0da08766c8b97f9c3270266bbc0bb47c1b0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
