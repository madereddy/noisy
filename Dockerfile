FROM cgr.dev/chainguard/python:latest-dev@sha256:25c828c47bcf4d1614e501c6f8249076949a4ab546d6023ab842e4752d0c4f65 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c8f2f6597532921cbfcb7b7a4493c335321bdbad89f7686893305f3760c28a8a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]