FROM cgr.dev/chainguard/python:latest-dev@sha256:0dbec28ed9fdf1f515cd92262852f08b5c957ed281494e47b24341ed6c723b5c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e57e10d5d66dffa858fabd4cebdb8a0b5a3d02a40c76e87ec2d13a87de51e521
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
