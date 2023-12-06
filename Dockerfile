FROM cgr.dev/chainguard/python:latest-dev@sha256:c912dec1d872e7775462828d0bf66f741ad05f6db320111dbd8757d571d8bc13 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a126caf48a08ecb206d347d7097302508d883c616198e6823fd54d5faae68bda
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]