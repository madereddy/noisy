FROM cgr.dev/chainguard/python:latest-dev@sha256:79b26fa37270f4029d8dd15f76633c006e3270822069655504a477d172b0150b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5f92a56e3421af36f6840b68cf27d5198105c48c87cecf8863edb38c39100394
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]