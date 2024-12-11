FROM cgr.dev/chainguard/python:latest-dev@sha256:5f8f4d8e09acf4c6807e2b94703995fef215db7f8a7fe9a0cad3576fa2069b59 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a2fc83d0c025dd354c826af42f8a88471372d35de19b88aeb2fd1a041d89a6a4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]