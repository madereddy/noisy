FROM cgr.dev/chainguard/python:latest-dev@sha256:bd6cdf89edbce0c6e09cbfa634bc1d279236035163b43b043f9ffd45ac81a65a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:11857e623e3869769d46f875533358a4658c6e08263cc9dafc32711a4a36c8c7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]