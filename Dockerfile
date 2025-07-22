FROM cgr.dev/chainguard/python:latest-dev@sha256:9d2be9b96ad17eda14e653708e4948ebd61dd57b65bd07ba1d6dcbfd3e49a1a0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:08c3327089fd3654746519c0eaa762e3bc52c6ed8f50f908821756b8a1221056
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
