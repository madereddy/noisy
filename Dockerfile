FROM cgr.dev/chainguard/python:latest-dev@sha256:e71ea77e3584e9a776cc7f013285b6e019f356851534bc62901fad34557a719e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:435ebc07441f0a8292d2a733bab01e66bae1c1506ffd6112def713885abdc1e6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
