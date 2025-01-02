FROM cgr.dev/chainguard/python:latest-dev@sha256:ebc0a0590256a939ff57d18a78e1d69ee156ea5745ec366110ab4d1e332b34dd as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:71dbbc42e33f405d403df86bc6d6c79d9054b190b11c2a7909086e4906118a62
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
