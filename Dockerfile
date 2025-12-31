FROM cgr.dev/chainguard/python:latest-dev@sha256:0bd4eff2db40ace62f50131d882d88057a41c998a0e215e42ff85fb6def4121d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:df0b981e02f6f8f56dd5fca37439255e0ba3855dd613314fb0c6b6db464293fa
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
