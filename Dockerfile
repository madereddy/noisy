FROM cgr.dev/chainguard/python:latest-dev@sha256:9f720cffd75a6fdbfb0482c68c9d4c2bcd7883e104faf6bf81af52c7a299b2e9 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:be8106b35d26afee7e4c81efc80cda19e60a3b20bc759f2f71e799eea3d3eaf6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]