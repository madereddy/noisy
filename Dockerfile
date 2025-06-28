FROM cgr.dev/chainguard/python:latest-dev@sha256:d447718eb6e6ab2f0f4c9bd41e7559e3f6a67a66536dec6b103239c8beb04ceb AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bb629fd022723f8d5eb990a71f18572d29c8c1630e9f3cbd1577501599d22eef
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
