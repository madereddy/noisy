FROM cgr.dev/chainguard/python:latest-dev@sha256:ee4858fcdaa85e411c0c7aaa6aa82f60c51b6fb6bc9b2aa6fb925fb3aa4d6e90 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b8d89aeaaeb245d96354c94cf054b5ba0797914677a226d268855ae4f40282de
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]