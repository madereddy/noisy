FROM cgr.dev/chainguard/python:latest-dev@sha256:e7bd19ed041e872153b5c38bd6170d361b5788fab61fc91edd5ba8768c1a93d5 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:71dbbc42e33f405d403df86bc6d6c79d9054b190b11c2a7909086e4906118a62
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
