FROM cgr.dev/chainguard/python:latest-dev@sha256:1b66369f2985c906d1713152da2d68f6752dbf46cef97304d00224d8c1e380ff AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:172a288df4aeb380077d5efabdbda0da08766c8b97f9c3270266bbc0bb47c1b0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
