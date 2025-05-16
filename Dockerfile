FROM cgr.dev/chainguard/python:latest-dev@sha256:90ba84b2bc7943abb510837069a86f69d2c9907c6e9e8f0564b76856c0f0be51 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4d6554b55830cb531e3b96d97916ce2a6bd68aea5b98585bfe9c799c518d9dc4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
