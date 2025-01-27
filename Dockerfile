FROM cgr.dev/chainguard/python:latest-dev@sha256:03e4584d7f79ad60d0be8b68d4b2b48134df1708d1a0c28f5ec3f6df5321c928 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:807a80038a7545f2780c50bbbf900bf8bea0e0d8a9e59d7af8e62e8b5fbcd319
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
