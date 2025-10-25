FROM cgr.dev/chainguard/python:latest-dev@sha256:e097449e591da76c89a8f7fef9abdc1b2d7d41644f42e7dbbd6fbf819572d6ee AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b1da912e82db2c234f15b34c90bf00fc959c52d07f9b2787bebdebe844f5f6e2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
