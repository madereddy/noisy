FROM cgr.dev/chainguard/python:latest-dev@sha256:fad84bba3b7caa0ae58da7537e5184325b6f9aea6166b5ec3620848edb832ac6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b9328fd1f02d7836c7a75b0423ea9b0098e1cc10f6d3b9398bac5ebb4410f316
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
