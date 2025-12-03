FROM cgr.dev/chainguard/python:latest-dev@sha256:a42d719241118ca2554cbf59f4b0e3d20f29ff14c32e9e7f5ad3a8c812a73777 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e080491bb0eb05cc538160fe476f36c7b1ae4fde454ec173677a0e32cba89b26
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
