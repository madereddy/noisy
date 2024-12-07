FROM cgr.dev/chainguard/python:latest-dev@sha256:ef2d25e44389622761fa5a6ecd1c8be168e6ede22bcad4f13b603b5360a80128 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:befe3a041ad0a2cec97f1a62cedcf088babef3f3b0b79155e08af6f97aec45eb
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]