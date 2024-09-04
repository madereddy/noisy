FROM cgr.dev/chainguard/python:latest-dev@sha256:36a804c74159b97305fa305dfec311f113b7bd55a28bda47796b3aec5c8abe6e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1c605c08b30dc8145d27c3e11964d3bfc237a5f96607e1d4fa338048e617266e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]