FROM cgr.dev/chainguard/python:latest-dev@sha256:9ae6d28d97fbcd7586ca8c5db77593081620f9f1cdf92834b3dea511417f06f0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:afff737e54552bb2da99773de75cb783f6c8c3285009581592f5b9e6bc4ab1c8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
