FROM cgr.dev/chainguard/python:latest-dev@sha256:39d3b461ec14222f7eadb6cf5c64153291c03aca514e09b307b77aa60d0f0a3b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1e753aa0ea651af8aaf7dd675d9dcfc2139bf13acd2cceb2dba3c39286a6172f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]