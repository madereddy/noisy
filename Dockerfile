FROM cgr.dev/chainguard/python:latest-dev@sha256:e4453f844869a2f510d464471440293e4cb9517f7f861b5f90dd649e41b12e31 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bc5a4d6a3ea2bf1d982d000a2366f28b352702059b0cc02f58ace2b830f1aaca
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]