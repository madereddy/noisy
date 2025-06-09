FROM cgr.dev/chainguard/python:latest-dev@sha256:7afb09b5eb12528c36a8b1fc1bab2045a6218cade155dbc6cb936e9756e29c84 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5aa7ba42455f6367df5120bf1225add6310cbee6f112a474a80b971ea26a6928
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
