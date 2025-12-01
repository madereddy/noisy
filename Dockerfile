FROM cgr.dev/chainguard/python:latest-dev@sha256:a124a35622b5a7c085e4590d59b98037d4f055498e595d4bb20180e9db2ada31 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d2aeeffe317f8da2f13cd47faf29de0372b548de2b79a4566ce875d9d168b6ab
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.14/site-packages /home/nonroot/.local/lib/python3.14/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
