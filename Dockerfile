FROM cgr.dev/chainguard/python:latest-dev@sha256:cf76b994aef3f78e128a0e199841cca70cbb80d61dbeb833aea389313629269b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1bc4d08e3de90c60e8526deb81534dbf3a4b5de9fc46c12a3c3de2284924f914
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]