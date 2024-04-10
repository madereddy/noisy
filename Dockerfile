FROM cgr.dev/chainguard/python:latest-dev@sha256:5b4203b3f6bd2fb9bf781c25f4ebaba7e61be425c2d953c4bb729a47d63e794e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a8cc6a296daaa162d60d09b3ebf33a5766e31c17c815a05eb1837094a738b8ee
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]