FROM cgr.dev/chainguard/python:latest-dev@sha256:255af1bad580e902ae0cf634cee6cdb83fbd7047513b11a7595dfc98c8422e5c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:383288e970f02b7ab0a3f4f122c5f83c9a6f85ab1af33a5af71e85aa9da779de
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
