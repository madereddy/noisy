FROM cgr.dev/chainguard/python:latest-dev@sha256:6b00986e333f3540ca11476ee87612c43d4a35a7df49c9f80ce7a9b0383b91d4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3792747455b65ebfcb8e193d24617aeed067975a6e64fdb1c507ae482f305459
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
