FROM cgr.dev/chainguard/python:latest-dev@sha256:1317aa66fec4b9735101d38df69c9fc1cc1e8e045ec1d11ddaa2e976005e2b60 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:87bd6a67a50c5aa1f9b03b38d1c914594248310778d0e055c48c9cb00613cb06
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]