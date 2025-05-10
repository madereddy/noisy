FROM cgr.dev/chainguard/python:latest-dev@sha256:3fdb6930e2b0b4631e42d99bb1d1fa9a85bc4560ce2e5bc5ce5057fe0550b9eb AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ed6a2d722024f3cf86347f8cc6d2b95a9f1894c7ddb84caf97a4b253a0616e5b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
