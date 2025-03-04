FROM cgr.dev/chainguard/python:latest-dev@sha256:2a94e33cfa90eb3b6753453129356e08065413676f8a5f64181fe4818c50d6c1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:90754693c030f39d0619cdf97971dcae0c94a23b4e354e8fae8cb1d6d746afa5
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
