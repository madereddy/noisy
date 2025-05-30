FROM cgr.dev/chainguard/python:latest-dev@sha256:d2c35dfddd8e1339263ce3fdd19e789cbca9c9d39f2d99b09a302b7c275ad400 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c0d3dc3a20d99bbb0423d1676d94f92ef6e608f745b261d2475e3ee8d404d46c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
