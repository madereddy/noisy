FROM cgr.dev/chainguard/python:latest-dev@sha256:7d78e97bd1bf71a44166eeec161ffa14df56ab8f22c75b6f8aad0439d23a650f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fa1f81a0bf96988a576e7f03078b8461d4af90e5585236f8a37e9bafaf81468d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]