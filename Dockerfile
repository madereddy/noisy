FROM cgr.dev/chainguard/python:latest-dev@sha256:67590fa0aa47e926db2bb248dc70de6c2265debcef62cbd320601881ddbfc49a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:396753727a726e5bec91a16eeb239e2959320f79bdf9c33bdd4eba876d4d3c86
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]