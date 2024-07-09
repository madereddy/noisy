FROM cgr.dev/chainguard/python:latest-dev@sha256:78c327ed9c3bb20fcef2226452b67c5071b03e51de35048acce21e4ae319e614 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8ffe47b9158f5908ebaad5bba092913ca8de8ea3df6b5caefb8818629cc5b5f1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]