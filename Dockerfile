FROM cgr.dev/chainguard/python:latest-dev@sha256:d8bacad8da41bec3b7fcff09837568c8de604c2fd761a0250d2af35119b1c328 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4ed46c781e1d87088b9d35828a53a2bb58f65ec9c2ff34e7df2a37e93feac643
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
