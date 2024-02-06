FROM cgr.dev/chainguard/python:latest-dev@sha256:7af0b89d0dea414f33dd1db87a3942744108d73648f8902af09948baa35baac1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4a1b3941e0c451a453637a7aef9db386772e6a8b2262135f7f2c43bb3fd085f2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]