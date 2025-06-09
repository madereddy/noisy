FROM cgr.dev/chainguard/python:latest-dev@sha256:7afb09b5eb12528c36a8b1fc1bab2045a6218cade155dbc6cb936e9756e29c84 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3814a4c4b3f1d2929007782bbc5cfcf0d7934986c07806d9952db0d3d9288d64
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
