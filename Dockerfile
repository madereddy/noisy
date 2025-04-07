FROM cgr.dev/chainguard/python:latest-dev@sha256:58864372c172ebf84f42244281c4bed2f9cdc98451b6f55839bea35db2f56ec0 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fb3e7d0de3245e05df3b16aefd6a0bb250a708201d4fce60f7de17a40121d26f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
