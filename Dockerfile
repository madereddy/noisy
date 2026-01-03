FROM cgr.dev/chainguard/python:latest-dev@sha256:2ea83e2dc2afc90e617925c7af227e88f52cd4b266aad1714c55091a21309da4 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:66a97fc45cfec264f1a42ec378af8f168667eb47e501dc2c2b5883f920a5827c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
