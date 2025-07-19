FROM cgr.dev/chainguard/python:latest-dev@sha256:a3d3a0d10d1db83b83f61e082d59d5cdddcd92f8ace43642b5d14b4a12624355 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:557411150431db773abad5967a1ec063f35f884828fa4c95c35b9078f3ac50ee
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
