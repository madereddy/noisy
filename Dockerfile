FROM cgr.dev/chainguard/python:latest-dev@sha256:20252c65f85d26ac56aeb2811e7a08afbe24c276d9c935cd10711fd417a8bedc AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:34c0aa496379c56dc18bc0e1771fbbe4a5da33543c22e2c1468d6a76f14e3680
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
