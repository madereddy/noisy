FROM cgr.dev/chainguard/python:latest-dev@sha256:549a9e31a14339d7d35571e10ed6b72b82eacd6282a83fdaada620d9b57d0476 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8f69b7d33a65d7b3833797301e0f94f95b0dc16662c3e22d7d1db9c8ebbf9c8d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]