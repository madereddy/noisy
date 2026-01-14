FROM cgr.dev/chainguard/python:latest-dev@sha256:22f5e61aee4674dbab203655a7a4530f4f7a9e08b81ec781e68a8c3230ae07f7 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c61c2d11da44d85e79d8957bd1d21ba4b0313e96801b460bb3f44d256e5beb58
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
