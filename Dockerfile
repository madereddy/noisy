FROM cgr.dev/chainguard/python:latest-dev@sha256:9ae6d28d97fbcd7586ca8c5db77593081620f9f1cdf92834b3dea511417f06f0 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:aff11fb801109cee35db8f90412c78d6a242f4f105234764d33238553cc5d870
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
