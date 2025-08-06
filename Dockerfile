FROM cgr.dev/chainguard/python:latest-dev@sha256:b75d0c87f3a7ffe86ab330009d78a3d2d1c7f1b5cd784bdf8429ff9882192622 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b4e613576560761bdc76b3692e8020e1e44303a56048368d8f4f98bb16d245bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
