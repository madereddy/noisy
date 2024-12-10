FROM cgr.dev/chainguard/python:latest-dev@sha256:5f8f4d8e09acf4c6807e2b94703995fef215db7f8a7fe9a0cad3576fa2069b59 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:befe3a041ad0a2cec97f1a62cedcf088babef3f3b0b79155e08af6f97aec45eb
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]