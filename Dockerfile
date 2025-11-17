FROM cgr.dev/chainguard/python:latest-dev@sha256:cac95f01d791abe0abdc183b59628b191a54f02a2d55b7251d12080108fdbe29 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c9faa43ce2bd9f858ba676c8c6e6386a2f4874ebbf63ce2b1fb0501ee2415265
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
