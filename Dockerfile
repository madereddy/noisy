FROM cgr.dev/chainguard/python:latest-dev@sha256:0f56f36b195810bb0a935a9750f5191f451fe1a8f4f0fc80dc1f0344bfdf9b01 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2fa2e1d5396c78a166f4efa26d1661d89629d897d6c71a00c53d951427d2e8c0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
