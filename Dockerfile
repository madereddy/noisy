FROM cgr.dev/chainguard/python:latest-dev@sha256:be1b3d6016894d9275d10eb7cb688a0f7878c1c39d9d7a81c26d960948fd5cf7 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f4179a5be98b1a10d95d1cb9b5d8f83ea4b88da651f940b26d73404c327ba07a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
