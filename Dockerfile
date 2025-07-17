FROM cgr.dev/chainguard/python:latest-dev@sha256:73a4170142047ef73517e2245b66bbf83296348fa886c449084e0fe1bde0d657 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:218df92adba38017a5faa371c2c524d19f4f1bcfc551ca8055820b866ec1ebf1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
