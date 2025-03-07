FROM cgr.dev/chainguard/python:latest-dev@sha256:496738ae51d16cd9142cf150254cbaf7304bc83384b2a8ab9f1a20cc464dc0ae as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3792747455b65ebfcb8e193d24617aeed067975a6e64fdb1c507ae482f305459
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
