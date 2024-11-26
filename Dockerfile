FROM cgr.dev/chainguard/python:latest-dev@sha256:87e9900de3407486a5f61458906bd36cade36aec9be236a8f445db049235f266 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e7e242e9f587737df9864210c90810bbfb07a68d55ef8a2d314b8a3212fc10e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]