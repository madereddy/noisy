FROM cgr.dev/chainguard/python:latest-dev@sha256:d82d0fdf006fae0440edfb5353e7a569c7c5c618fb74169da97a72b1235d87c8 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0c2a6293bfcf74041f5858346db421fc617f7ceebd107577d8348b92553be6a6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
