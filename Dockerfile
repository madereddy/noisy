FROM cgr.dev/chainguard/python:latest-dev@sha256:da4250ea0b2c296f8520c90ffa3e7b12e634d94b9eb50021100e9b660749c0a4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0d2d388c31746f7ad6c8563d32c3929b39a8f2487a666d05a7c8095dfac0b125
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]