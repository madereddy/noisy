FROM cgr.dev/chainguard/python:latest-dev@sha256:5f04e7637ccc7e2460eb5abfffa7536ad5c67ac67cd90ab1f2c80054c35ed028 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:270ce628688ea2cf09f24f7eac2435a4af59598a3a642f23386035489a410dc2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
