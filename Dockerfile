FROM cgr.dev/chainguard/python:latest-dev@sha256:00fcbb3c469aa35ca364b0c67140445c0ccce7b2281b2f0cb9cbd7f23d85846f AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:136aad7020e00a98f617f3d3343cc7601b7823405eb2bc581eae5f5a8c21e8d0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
