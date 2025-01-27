FROM cgr.dev/chainguard/python:latest-dev@sha256:1a79bf3470cdf874c2105040b12eab4bf61b28b2d9d526ec1adc0dfde774d17a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:807a80038a7545f2780c50bbbf900bf8bea0e0d8a9e59d7af8e62e8b5fbcd319
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
