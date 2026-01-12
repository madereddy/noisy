FROM cgr.dev/chainguard/python:latest-dev@sha256:e74973526261c4ad07fb144bc1636f1b4b2d19f2c74d311a2040cb520276ca08 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:95d87904ddeb9ad7eb4c534f93640504dae1600f2d68dca9ba62c2f2576952bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
