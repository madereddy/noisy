FROM cgr.dev/chainguard/python:latest-dev@sha256:91d7334d89efd71b9d6168aae9129ad84afee85993adfddac100457263425012 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2fc6f46589ffc4eaffdde315ddd9e76f7da9255eb117349023d8e4507a558770
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
