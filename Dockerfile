FROM cgr.dev/chainguard/python:latest-dev@sha256:f81a5bf1332dcd61ee88ab285211005d8b1b27a6f483200b555ddf4bf0bbd8ff AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:92c3483c8ac7eda088e51952b744cce1f3087fe7560a5da672d918b7c57a65fc
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
