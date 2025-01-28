FROM cgr.dev/chainguard/python:latest-dev@sha256:7805dfaa784da1919f3479c497d03f4e6d6b2c5bf28a8968edf679b08a29c32c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:807a80038a7545f2780c50bbbf900bf8bea0e0d8a9e59d7af8e62e8b5fbcd319
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
