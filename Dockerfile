FROM cgr.dev/chainguard/python:latest-dev@sha256:e957d47693d3a9cc23ce7438f287d8332301b1adad0312d258529c5e3abfda68 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e7e242e9f587737df9864210c90810bbfb07a68d55ef8a2d314b8a3212fc10e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]