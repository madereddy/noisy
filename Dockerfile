FROM cgr.dev/chainguard/python:latest-dev@sha256:6d42e7b0b3663ef9f99e33ab98058d853c1b79eae8af62c21d7784ca06242c5d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fe4740c2caa7ee0bb8a7da188630a4188b33692ce21d71cf30488dcfd570e4a8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]