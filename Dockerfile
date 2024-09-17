FROM cgr.dev/chainguard/python:latest-dev@sha256:342d81dd35ec992d29a2c4e4b1f6f5ab37615a78c54aaa86c852ea99c9dee49b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8c17b4bb6bb24bdc071e316746f293477f9b9bf2deb46bfef340efcbc2fdf5cf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]