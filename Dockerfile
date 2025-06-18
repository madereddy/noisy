FROM cgr.dev/chainguard/python:latest-dev@sha256:6d464044cd4e56e31cfd29899dcc119eb87c3f806283194388f1c75bdaeca6fd AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:118cb4e86dd4277423720b67003cccea887a1fc6c99007466492c2119bc4d60a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
