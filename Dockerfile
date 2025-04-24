FROM cgr.dev/chainguard/python:latest-dev@sha256:8281b71966f72705e00fb9c4cdbf67556bfbb7c0ffa73bf88ebcf7f131245506 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ff9d2673795339cba1915439078feb62e140ef9d2f7eade7c263695f2b40042e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
