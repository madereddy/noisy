FROM cgr.dev/chainguard/python:latest-dev@sha256:d583c8203a456b7e016c61a5ecaf9d1f8153a1cba561e438edb5a1a1495ce031 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e7dc21120d9df2ad36b5b25bcf307ce62e7168810a82c7773cca5c9495339c8a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
