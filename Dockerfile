FROM cgr.dev/chainguard/python:latest-dev@sha256:cf76b994aef3f78e128a0e199841cca70cbb80d61dbeb833aea389313629269b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:be8106b35d26afee7e4c81efc80cda19e60a3b20bc759f2f71e799eea3d3eaf6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]