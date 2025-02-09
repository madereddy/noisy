FROM cgr.dev/chainguard/python:latest-dev@sha256:d598ae7b80819d68a81aa1550b853162cb930b859022fe7dac0d6f1c819eecdb as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f2e50419f6e4eb6400fef06f1bcb1fb713878780062b2d0588e59cf540619637
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
