FROM cgr.dev/chainguard/python:latest-dev@sha256:d56eb91964f17391ab9933079f89d6d2cd7b5bf5c2d10e1a33b2208c130da77f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3559f62cb6e38925fb97b9479612522abb4522c95b80e65e7f50e9e4a67cc0d9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]