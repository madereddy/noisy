FROM cgr.dev/chainguard/python:latest-dev@sha256:5bfd5ab3ab46014154dd7b118338fd4a7a2acf8943eb3eca4af1e91ce6a36a9f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8e1d8d13a046fbcab6ac1f68a0887d737d96c4355aab8e3d3031671a465ee047
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]