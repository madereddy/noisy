FROM cgr.dev/chainguard/python:latest-dev@sha256:07f7e8e7d95c997a29394b2bf4bcddc4b538191327d21931fecb36972e555872 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f67a0761e8c0af5b4fd7c94d7834b8d759815f283a00dd29ccaca6cd7089d39c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
