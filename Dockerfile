FROM cgr.dev/chainguard/python:latest-dev@sha256:619a84b84f8bb1f3c724d7c98c0b195059554e04ae92cb6f579efed6718d13ee AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:14afb7f0d9d217f3ef592bdcd02b301a191913c8d3c2cf39f63cfe2030cdd2b7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
