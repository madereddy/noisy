FROM cgr.dev/chainguard/python:latest-dev@sha256:09f4f51a187f66504d8a1c2ffa34a9455fee7c16ed7bb96f0ebc9be158bed459 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f2e50419f6e4eb6400fef06f1bcb1fb713878780062b2d0588e59cf540619637
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
