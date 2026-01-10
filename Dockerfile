FROM cgr.dev/chainguard/python:latest-dev@sha256:21a322a3b614b7d5334a686df7149a991bacab0e02e9fe920768c39551f0b3d3 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:66a97fc45cfec264f1a42ec378af8f168667eb47e501dc2c2b5883f920a5827c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
