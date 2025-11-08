FROM cgr.dev/chainguard/python:latest-dev@sha256:3d560bee136780da3d501de92bd8b9de55a388fb65d186a012cbae88efea1a3e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8af8850acf2827e9b1e140758359900c6270344a4cce8725cfefae92b3c7e328
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
