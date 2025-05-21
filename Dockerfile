FROM cgr.dev/chainguard/python:latest-dev@sha256:4cd06b43fca46f24925373e09356ab6028005a0225a54c6e4867921289477cc0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:92c3483c8ac7eda088e51952b744cce1f3087fe7560a5da672d918b7c57a65fc
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
