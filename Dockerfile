FROM cgr.dev/chainguard/python:latest-dev@sha256:422994bcdf2ef4258eb4fa5b350faec426c2f3c5bdde3c9181affb33d309ea37 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3dbdfe5d705096a1d18df13b4a055f85862440e37b93876f1ed3e2b2abad6739
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
