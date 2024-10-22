FROM cgr.dev/chainguard/python:latest-dev@sha256:44f96d7f5642b370a189c7403938c067c54d166307082a4dcc86e74c97ae8056 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c73e2dcefb8e97860ab0c0b374758df9b4938f023b56a1298526a645f6e6be51
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]