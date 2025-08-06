FROM cgr.dev/chainguard/python:latest-dev@sha256:51693823bf4fd7bcbf56fee2c9d100b263503258019f723288f796f1fdb5947f AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b4e613576560761bdc76b3692e8020e1e44303a56048368d8f4f98bb16d245bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
