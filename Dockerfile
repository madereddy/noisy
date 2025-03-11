FROM cgr.dev/chainguard/python:latest-dev@sha256:c394636ad24ad73f2e50a623dfb918ec0062a25a43715c33c54f70906c03ca10 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ac069eca3ddab59f2971d3220e124f3389fb0abefe7eb2624038d1e5e47bbc62
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
