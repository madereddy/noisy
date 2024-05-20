FROM cgr.dev/chainguard/python:latest-dev@sha256:03b630216f9fa76a0dedc4e7f6f40bea22b2fd56e32a625227d8135e9256c2da as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:11857e623e3869769d46f875533358a4658c6e08263cc9dafc32711a4a36c8c7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]