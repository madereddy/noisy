FROM cgr.dev/chainguard/python:latest-dev@sha256:e0d510f22eb2f2c6cf96b78a75ade9ce147acb10e3ff3bda807d0aa1442f1553 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:91d2e7e325288a456ebf239270fe91a14bcf1c04f931d1d04a8cb0569346b883
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]