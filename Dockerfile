FROM cgr.dev/chainguard/python:latest-dev@sha256:7f5dd74131223fba81f88168e88a921774ef42ea5269fb2dab44ec3ea66468ca as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e57e10d5d66dffa858fabd4cebdb8a0b5a3d02a40c76e87ec2d13a87de51e521
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
