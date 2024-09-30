FROM cgr.dev/chainguard/python:latest-dev@sha256:ff23b5a9971d51deaa5e12a7a3c3e53935faca67f563498d0d3176bff2d29302 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d36f443087be26e55b2bf18ab624dd17c8968a637c6bde750f80dc0c4ce81860
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]