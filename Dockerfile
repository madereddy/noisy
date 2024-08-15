FROM cgr.dev/chainguard/python:latest-dev@sha256:07f2883218700e144d55fa8f042fe8b6eb88ba0f80c713a560ae9ef72b46ba7e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e94bec761ec11f0a316faad77b795837ebd81f37b0c9f2ea59cadd4644e15087
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]