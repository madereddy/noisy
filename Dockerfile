FROM cgr.dev/chainguard/python:latest-dev@sha256:f4d352be4dbf850c0135a21b69bf9e334ca9c990fbdebb635c8ca4537ce43f92 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8485986f5483c93e0e154a6dd186695c0b218eab68ae6e72573df506b3cffdb2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
