FROM cgr.dev/chainguard/python:latest-dev@sha256:5a506f35d812a2b767f6807aeccb6d40b09e8e39bc0a5b9560f052e96b11de7d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fb3e7d0de3245e05df3b16aefd6a0bb250a708201d4fce60f7de17a40121d26f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
