FROM cgr.dev/chainguard/python:latest-dev@sha256:4df91f68e1387de2fd4b8664e908a57bc1e11f01bbc3077a26c232cc3f3fc972 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0d1fe818c0f946c68e87ed0967e5048c6736decf1f564dba850d371c70efd094
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
