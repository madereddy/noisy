FROM cgr.dev/chainguard/python:latest-dev@sha256:0ba7c37037fc1669dd600e3e5348ab0774fc07e504c714cb14bde02708d3290a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0d5b9954eeb7a71c3305bf2c39bfab22ad795931d804e15eb6358c8b57e4dac8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
