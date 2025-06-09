FROM cgr.dev/chainguard/python:latest-dev@sha256:7afb09b5eb12528c36a8b1fc1bab2045a6218cade155dbc6cb936e9756e29c84 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d100c2fc9b03eec266ff76e8f9bcda304ae10c3cb9a5b5bb5739cae5584fe4ed
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
