FROM cgr.dev/chainguard/python:latest-dev@sha256:339c79f7f3f664f5a1446a77ef90bebe48b2e2024467cf3277792a8d36150f1e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:62d8d564561e3f0680f4246677a7b790620f498119657f859dedd0d2348fae0b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
