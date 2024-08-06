FROM cgr.dev/chainguard/python:latest-dev@sha256:da05d36d8450c8dbc560eb0becf38e6c989b9b0af89770fa42437d4f6b479649 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1e753aa0ea651af8aaf7dd675d9dcfc2139bf13acd2cceb2dba3c39286a6172f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]