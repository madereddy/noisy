FROM cgr.dev/chainguard/python:latest-dev@sha256:8b792b8c2c50610c27685629b93dab90578d704a6e63019d9fce6d4a80ce7ba0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:df07729a6842572922ea04b17580ce397f141fbfb9f88265972a840f5fbc567e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
