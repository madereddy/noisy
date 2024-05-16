FROM cgr.dev/chainguard/python:latest-dev@sha256:56dd0b0c50f9cc8a6c9b849e085292282dda31f94a9cd57afcc887a5bdf9bd15 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5f92a56e3421af36f6840b68cf27d5198105c48c87cecf8863edb38c39100394
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]