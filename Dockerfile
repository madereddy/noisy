FROM cgr.dev/chainguard/python:latest-dev@sha256:a8d76ddeca2488dbbe26fed1d8be5813783372b93558c642f7ae39f8a8d0bf32 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a0ebbd2710712d947f80bd508d63d7a15da99b988c4a60ac1b7c015c51f511c4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]