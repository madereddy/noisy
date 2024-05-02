FROM cgr.dev/chainguard/python:latest-dev@sha256:f25d56d44a0d16bf9b272f1688e7367219d9b5cb9af12cda4ef9aa681ad053db as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4ddc5b072df584f13c734dbe0d8da48d72051a1ef2caacca3687fcb64f9cbd98
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]