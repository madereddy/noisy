FROM cgr.dev/chainguard/python:latest-dev@sha256:31e6df730a83fca0b81062edee476b035a1034e036cff73fd561242f8e6086d6 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8af8850acf2827e9b1e140758359900c6270344a4cce8725cfefae92b3c7e328
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
