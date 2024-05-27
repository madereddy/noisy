FROM cgr.dev/chainguard/python:latest-dev@sha256:70f97dd84e4f7f3962ee3dc46b0c206f583981ea3317bfb7faca3d6082d4d41e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:99ee1559c4632e06f293a2f03a2677e6bff371d37b4de6e21322715cb0697055
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]