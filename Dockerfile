FROM cgr.dev/chainguard/python:latest-dev@sha256:69fb65b317048024e5749fcd292a847d207dc0963ca0916be7333e2c513da39a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fb78813b39c4d8f5caf3acfe5d048f366b9708920eadb5ba768e1b0ace31560b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
