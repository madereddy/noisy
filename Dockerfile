FROM cgr.dev/chainguard/python:latest-dev@sha256:7b61b6c301bcea7d7afe4f52bbbe12025e3b18671616dc0cf5568a6dc6087c7a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fb3e7d0de3245e05df3b16aefd6a0bb250a708201d4fce60f7de17a40121d26f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
