FROM cgr.dev/chainguard/python:latest-dev@sha256:d1142f4047abd80526fa4917faf4b570f1a1959f77a073388e4b04f4af2a4c0e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:678db9554b6e1803adf77309a6e0ddee394ab0cf8d0b31f637bac385777bae56
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
