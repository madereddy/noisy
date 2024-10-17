FROM cgr.dev/chainguard/python:latest-dev@sha256:67590fa0aa47e926db2bb248dc70de6c2265debcef62cbd320601881ddbfc49a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:56538572bc98e93976692e3dcfe984352bd7c72eef32b3947730c0b3a43ca802
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]