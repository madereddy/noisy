FROM cgr.dev/chainguard/python:latest-dev@sha256:4e82e45bbcd23eb6775b5ccd26739babb4c015fe6b520080f641656a789513a1 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4d6554b55830cb531e3b96d97916ce2a6bd68aea5b98585bfe9c799c518d9dc4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
