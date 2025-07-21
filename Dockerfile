FROM cgr.dev/chainguard/python:latest-dev@sha256:d8bacad8da41bec3b7fcff09837568c8de604c2fd761a0250d2af35119b1c328 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:533dfd470b306239285e33c08305b0f4c8a8841edde49e05e6bd567c5424d8fe
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
