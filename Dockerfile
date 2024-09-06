FROM cgr.dev/chainguard/python:latest-dev@sha256:4d6f418a5dfad7bb4dd2641b5498d3aa53708073c0e1909fde19cf3568c8aa59 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f7b840c6b5b3144359e7801ad00ecb5483acd7d6957aaf34b4ecdcaed3532c52
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]