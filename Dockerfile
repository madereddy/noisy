FROM cgr.dev/chainguard/python:latest-dev@sha256:4f4cd9811edba80516df938db4d89b353d31c6d59aedcb658aeb2d89854b7185 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3792747455b65ebfcb8e193d24617aeed067975a6e64fdb1c507ae482f305459
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
