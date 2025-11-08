FROM cgr.dev/chainguard/python:latest-dev@sha256:3d560bee136780da3d501de92bd8b9de55a388fb65d186a012cbae88efea1a3e AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ce8cbd5047393b5c7d6e0f27c89f2adcfc5c2dfdcc755f85c3937f684e7d9875
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
