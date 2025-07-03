FROM cgr.dev/chainguard/python:latest-dev@sha256:548b3a9911c1cd0b2655e082044b63b3dc57e05728139d7ebb23f04dd9f5abe1 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3f7e24839e1831eb79f694227d31ec2a2f77c917a883948d3149cc41c85ef5ce
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
