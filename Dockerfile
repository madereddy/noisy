FROM cgr.dev/chainguard/python:latest-dev@sha256:b4dad01021333e2a4deda1d1ef7df375b407c1d68d03df7e00a3fd6f7d318387 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:270ce628688ea2cf09f24f7eac2435a4af59598a3a642f23386035489a410dc2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
