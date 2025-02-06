FROM cgr.dev/chainguard/python:latest-dev@sha256:ac49d1970cde236c8baac9d35aae46c09277fe8a24a19af2b049522df6a1fc51 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:40b5c7ba23f16cb4d88081bfadf12912be667f8d50cb467b967cb85600d2daa3
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
