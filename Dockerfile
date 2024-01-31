FROM cgr.dev/chainguard/python:latest-dev@sha256:c7983b23312cfc4fcbebbf8c0fcb1ed83c3d4634ced078b7fbc10fac93044b36 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a640f1a266988d5a44bc75c15fdd34892183b4019550f8d66aa9e3c885018658
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]