FROM cgr.dev/chainguard/python:latest-dev@sha256:cacf65cb67d586dc10c8631d9f2c3fab17b110ca6073d7e71968602b095f9110 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:93fcf61f278621f8c9bf56a0a54bc41309444ef67b8fc7f27bc9bfd860013585
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
