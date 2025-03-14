FROM cgr.dev/chainguard/python:latest-dev@sha256:ab3dc2c3d1db9ac2e5c15987a6064dec45a8ea0743ce3930614305cfc58d8c69 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fd728e07eea2a5ea9acef0050720485f2a9738cef52ec8931e18cf94ba12c7e2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
