FROM cgr.dev/chainguard/python:latest-dev@sha256:03e4584d7f79ad60d0be8b68d4b2b48134df1708d1a0c28f5ec3f6df5321c928 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:77db97399ba0a489886358c80a45bc1637af259327f423fe16ffe767ff8e57d2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
