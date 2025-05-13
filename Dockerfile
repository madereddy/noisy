FROM cgr.dev/chainguard/python:latest-dev@sha256:568947a2b6dd940d18546a7c0364c0037b56828d04f99dda17c08cd67f8686f5 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ed6a2d722024f3cf86347f8cc6d2b95a9f1894c7ddb84caf97a4b253a0616e5b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
