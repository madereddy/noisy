FROM cgr.dev/chainguard/python:latest-dev@sha256:e097449e591da76c89a8f7fef9abdc1b2d7d41644f42e7dbbd6fbf819572d6ee AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:7e8d50cf67683131e6d8cbad3a95ab1b960c2ce815f24a2f4527f48a18d7b323
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
