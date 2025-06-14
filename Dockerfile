FROM cgr.dev/chainguard/python:latest-dev@sha256:3e3ad4d787d0ee40e4b1cab27d2d5d6b0d213937ccd0aefaf8ebc1e8fe6dbd52 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8d7bf8f0939c186fc2dbfc252a22df0fcc1ecef2490ea3f124aa448e14bf19c9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
