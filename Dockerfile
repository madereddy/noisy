FROM cgr.dev/chainguard/python:latest-dev@sha256:09f48e1aaf01887e8e25d699aac02f3352841d2b3a3799a30481c8291ab0103c AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:17cd737bfcfd3fd8b7a32036dcbbf80ae9e85c503f0b46d755e31208a46a392f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
