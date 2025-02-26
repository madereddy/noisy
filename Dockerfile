FROM cgr.dev/chainguard/python:latest-dev@sha256:23722aba23fb0e96250fc6ea04e7a278acb5ed7c6fb5197d7f456920c85604f9 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:eb676f7c8a373d47d13ca954a718e8860eb53ac3cd4fb9be7f18c683d4339924
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
