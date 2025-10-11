FROM cgr.dev/chainguard/python:latest-dev@sha256:845c4c458aafc14131ca45be9d21b03f9bce55e7b99b91bbeac874935682ad9e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:114dada9623f2ab4eb15fcf9a9abf32d29cff62ca8348035214d4eae3827307d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
