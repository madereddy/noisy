FROM cgr.dev/chainguard/python:latest-dev@sha256:36039651c0ac69dc0e38fb1c7993fd088b02641cb6f78a7ff5e6f28f70b9b8e5 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c09ac5b32eebb821ac2d5d8872c3a73bd76ab5c5e6f8f70862f848a67a32964d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]