FROM cgr.dev/chainguard/python:latest-dev@sha256:f7f6bb2206231aeaeb047d42747ae3d08a102fbcd5b1b9bb8e5809ad34562970 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b6f495ed363328b0600c5b9b8cbf5e76c4bb981a7641988722123024a97b41b6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]