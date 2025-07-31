FROM cgr.dev/chainguard/python:latest-dev@sha256:71271354480c32cb2adcbc8548d075a13a592bb6704da34ef79f4b5c40ae0b39 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:7efa3128e165b02b4ca81c87851218603b7788bd217d4d9b31e3cc66105e9288
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
