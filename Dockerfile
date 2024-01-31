FROM cgr.dev/chainguard/python:latest-dev@sha256:9003bcb5de882c3b023314580cd7600b2e2baf3cd45d78e3cb50a8060771d207 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a640f1a266988d5a44bc75c15fdd34892183b4019550f8d66aa9e3c885018658
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]