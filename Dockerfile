FROM cgr.dev/chainguard/python:latest-dev@sha256:644de8cd529d28af198e476ce9949f365d5002301f4ccb02a895bfe8fa49439f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c7c2a5c9dda407966db7b767aca6f06413941176428eb162b5a9499940407786
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]