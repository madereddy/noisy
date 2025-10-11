FROM cgr.dev/chainguard/python:latest-dev@sha256:61c2ee7e76c78b078bcd4fd8eb839d7f20ce4723210512472bbad57cdd8a89ab AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:69514cf8cb0df3472770e225bd1c0fc7617e1f1eb4fc59447922a2ba4806b04c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
