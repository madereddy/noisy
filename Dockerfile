FROM cgr.dev/chainguard/python:latest-dev@sha256:21a322a3b614b7d5334a686df7149a991bacab0e02e9fe920768c39551f0b3d3 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:95d87904ddeb9ad7eb4c534f93640504dae1600f2d68dca9ba62c2f2576952bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
