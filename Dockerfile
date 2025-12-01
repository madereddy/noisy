FROM cgr.dev/chainguard/python:latest-dev@sha256:fc0000b0ab130abd484b065e7b0a691eb0e393b86efc9f5218b226446cd2bcff AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d2aeeffe317f8da2f13cd47faf29de0372b548de2b79a4566ce875d9d168b6ab
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
