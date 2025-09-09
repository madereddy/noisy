FROM cgr.dev/chainguard/python:latest-dev@sha256:342d144118b8c8fdb551694a364766f331d218302b1cd491866bc40f3222053c AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:14afb7f0d9d217f3ef592bdcd02b301a191913c8d3c2cf39f63cfe2030cdd2b7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
