FROM cgr.dev/chainguard/python:latest-dev@sha256:7a5375e4b32365c5ac2a9eb62f2b428892b8824fa82fd6b0310c5d55d18fb85d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:383c8b591d31dd66d36fc0a565a24c7ce7ed04df63114f0074489bc13a8dc925
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
