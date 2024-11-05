FROM cgr.dev/chainguard/python:latest-dev@sha256:7d78e97bd1bf71a44166eeec161ffa14df56ab8f22c75b6f8aad0439d23a650f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a6e6f139e1f3ec9238bce5ec72d9edfbfc2bec727d34263007d2df49708c96e5
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]