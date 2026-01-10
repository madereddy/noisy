FROM cgr.dev/chainguard/python:latest-dev@sha256:2ea83e2dc2afc90e617925c7af227e88f52cd4b266aad1714c55091a21309da4 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:95d87904ddeb9ad7eb4c534f93640504dae1600f2d68dca9ba62c2f2576952bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
