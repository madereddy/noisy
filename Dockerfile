FROM cgr.dev/chainguard/python:latest-dev@sha256:97d12c3636e3191a742a18427e40834cd48b964042d05f6b84c95bd3cb93ff45 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8d7bf8f0939c186fc2dbfc252a22df0fcc1ecef2490ea3f124aa448e14bf19c9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
