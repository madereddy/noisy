FROM cgr.dev/chainguard/python:latest-dev@sha256:47455624f1081267acc700be45da753a3ac88b572465db5ba4d8d19b2e741684 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0d1fe818c0f946c68e87ed0967e5048c6736decf1f564dba850d371c70efd094
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
