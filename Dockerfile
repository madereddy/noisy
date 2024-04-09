FROM cgr.dev/chainguard/python:latest-dev@sha256:7dee8919dd14a2bf91e93d8848519819e806a4a6d3aff8b7ea8fbf5bbc2d71e9 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a8cc6a296daaa162d60d09b3ebf33a5766e31c17c815a05eb1837094a738b8ee
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]