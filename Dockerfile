FROM cgr.dev/chainguard/python:latest-dev@sha256:5bfd5ab3ab46014154dd7b118338fd4a7a2acf8943eb3eca4af1e91ce6a36a9f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d3dd679ddd2cc6ad2452024b5f9760f4c009e2e6628776105e71f4501b52be05
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]