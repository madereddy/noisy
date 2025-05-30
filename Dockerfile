FROM cgr.dev/chainguard/python:latest-dev@sha256:bd7669469198d5030f81bb62347b22e53133f3cdedb68655d648c2b94db7e6ac AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:333fdfd22fd214412c71b407a4d16d4e2aba41e5b34e683c81ecdb917f7d070a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
