FROM cgr.dev/chainguard/python:latest-dev@sha256:b75d0c87f3a7ffe86ab330009d78a3d2d1c7f1b5cd784bdf8429ff9882192622 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fa2bec33f8419f12f425b974908152ce3f464aea895f2337cba98fedbd96de71
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
