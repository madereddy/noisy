FROM cgr.dev/chainguard/python:latest-dev@sha256:9bf10af912a9203b9f788f17c6b6f98676a91df9b02d0b26109ac139faea7896 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ac069eca3ddab59f2971d3220e124f3389fb0abefe7eb2624038d1e5e47bbc62
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
