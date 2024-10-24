FROM cgr.dev/chainguard/python:latest-dev@sha256:a287c47b92f41107e07d825738607d6cdd7a85121e5bffc917303815724d4dfc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:84bcee609619750752fcbd3e853709b210b8028df354f98b8dcf6538ce420e94
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]