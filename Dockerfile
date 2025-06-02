FROM cgr.dev/chainguard/python:latest-dev@sha256:0bce29e9ce9912725ad2555f13f3fdb21064973041859646509f18cae2025ddf AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:08e91d4a86cc9e39829b867b0722234a6440b8ff9faedda57e542f8bf8c2b0c5
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
