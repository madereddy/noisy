FROM cgr.dev/chainguard/python:latest-dev@sha256:edb09510fa6f7b8b4876207346a85d62d3b02d1ba896f1c44b33e07fb91fc94d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:34c0aa496379c56dc18bc0e1771fbbe4a5da33543c22e2c1468d6a76f14e3680
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
