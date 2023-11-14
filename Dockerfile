FROM cgr.dev/chainguard/python:latest-dev@sha256:b462e3e5a572225ed3d89e92c6eee6a41ba4bd2058612130494979f9bdab162f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:14b01460efdfb42b298cbb31807ed235d2661bfe576b849fce59614818302301
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]