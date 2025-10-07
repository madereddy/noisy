FROM cgr.dev/chainguard/python:latest-dev@sha256:e71ea77e3584e9a776cc7f013285b6e019f356851534bc62901fad34557a719e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ba57d249a2ecf076795604b522e2a2945031bb70607e45e09e410e9b8207b715
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
