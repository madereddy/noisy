FROM cgr.dev/chainguard/python:latest-dev@sha256:5f6d2b206a5228c3b2037796ef06e4995977d767de3358e4ef5856c6830f6c67 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a4c167ce35fdf4b7edb33084709f5d29906e3326e9cf13d1809ec032c847fad6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]