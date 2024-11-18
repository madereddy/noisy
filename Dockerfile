FROM cgr.dev/chainguard/python:latest-dev@sha256:3d576a0d94b05c0da7fba83c8dbf1d909a61a95132d3f65b409b3eb01bf18633 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:653ad741c10082637dcb1b07146bafd807548ad7bd1e89cdc01ccac057a9f7ca
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]