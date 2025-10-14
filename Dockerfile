FROM cgr.dev/chainguard/python:latest-dev@sha256:edb09510fa6f7b8b4876207346a85d62d3b02d1ba896f1c44b33e07fb91fc94d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:22a86d2fbc27fe5c4c06fc362a94e4fbf7b4fde6c3c49462c8d3168e340fbe48
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
