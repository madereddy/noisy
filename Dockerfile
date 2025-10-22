FROM cgr.dev/chainguard/python:latest-dev@sha256:8e01369050822ac87b5c2167e2d7a527e9ee9fb014336475591ed64a0cfdc68b AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c651f2db0fa2e2f08fdfe87a91385f1084961590d3a660d2e22ce61f46774673
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
