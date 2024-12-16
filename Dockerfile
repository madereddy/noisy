FROM cgr.dev/chainguard/python:latest-dev@sha256:e22e86b81a5ef8bf50ed6899e5d55ae44725791febde5a67bc2e8afd5939bad6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b69271bb5c3f06f5afa4c40a77867784e907408ab991e4d6e907f5aa796b87b8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]