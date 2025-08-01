FROM cgr.dev/chainguard/python:latest-dev@sha256:251bebc53d005d78dddb22dee13fea68a86a5246bf65ade877f0529b78e2f14a AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0e8989f79bc33e6219661e165fd343e281a21a8e94457ddb07af446860c9baa0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
