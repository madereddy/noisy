FROM cgr.dev/chainguard/python:latest-dev@sha256:ef2d25e44389622761fa5a6ecd1c8be168e6ede22bcad4f13b603b5360a80128 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9f93210d15a82eed4a4167817871ee7f1adf901256aba4bfdebc51bda96e0668
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]