FROM cgr.dev/chainguard/python:latest-dev@sha256:5c94ee31386cfbb226a41312a05f8f61b0d08635fc13812891be062c334d5428 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c61c2d11da44d85e79d8957bd1d21ba4b0313e96801b460bb3f44d256e5beb58
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
