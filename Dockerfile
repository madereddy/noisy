FROM cgr.dev/chainguard/python:latest-dev@sha256:ec4d7d778f4b3d535102e680ba343608e708bd08ec2cdff3b7fd909e8c38e5b1 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:36f63157191eb52f3296e149e009b6e5a989f5fa03a2e307728545e3cc46fcf0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
