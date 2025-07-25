FROM cgr.dev/chainguard/python:latest-dev@sha256:1cd33a5007bf8a9e62110ae7345eff5073442869b1aba130ee36ee3f3e0bb6ae AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2fa2e1d5396c78a166f4efa26d1661d89629d897d6c71a00c53d951427d2e8c0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
