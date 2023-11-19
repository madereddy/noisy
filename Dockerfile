FROM cgr.dev/chainguard/python:latest-dev@sha256:f04473351a6d45ef71b36acf8aa9b959cb2dd41ba275911cb9f04573961d98c2 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c09ac5b32eebb821ac2d5d8872c3a73bd76ab5c5e6f8f70862f848a67a32964d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]