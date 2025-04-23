FROM cgr.dev/chainguard/python:latest-dev@sha256:ed658f707d03311668d05a0505eb5154bda9a5343e9e0683cb7f9e612ba7039e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ff9d2673795339cba1915439078feb62e140ef9d2f7eade7c263695f2b40042e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
