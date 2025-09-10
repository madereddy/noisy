FROM cgr.dev/chainguard/python:latest-dev@sha256:79a3c0faff705cfd3963399c9835e079a24b5655883e42171fe1a6bf27e794df AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:80c9b043c8f231f130b0d0dd71cfbdc79e8a9855430ea2fad0ded34de12116c4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
