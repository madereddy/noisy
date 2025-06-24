FROM cgr.dev/chainguard/python:latest-dev@sha256:eb677f2d18459e6ac274e441ad6a7c932faafc79c2cd81efd10c1eeaa96ea4c0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1e8da8caa7cd3544aa2e5f3e447f99458ae44fc6a12b5bfe8b47c817367cb45e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
