FROM cgr.dev/chainguard/python:latest-dev@sha256:12f318dd067c0633a4509a92167e30d70e5d42e2164b0b01c11ab89acb6c611d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bf7ee653965b385aae959163a7c799338a9de7385d60e9879bc7fac099d71c47
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
