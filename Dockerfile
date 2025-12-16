FROM cgr.dev/chainguard/python:latest-dev@sha256:4f38919abd322d122a8219a7b6147e419806c29ad3b269596288bf61a0a40867 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:270ce628688ea2cf09f24f7eac2435a4af59598a3a642f23386035489a410dc2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
