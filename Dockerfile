FROM cgr.dev/chainguard/python:latest-dev@sha256:5bfd5ab3ab46014154dd7b118338fd4a7a2acf8943eb3eca4af1e91ce6a36a9f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c6718c5d43ab9e27a0e1c0aad6b12c01f992bebd9fb750366c44192d2621e37b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]