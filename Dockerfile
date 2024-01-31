FROM cgr.dev/chainguard/python:latest-dev@sha256:1a8bc4369d7fd3832c05042526f5016d2f9ada8430c2edb7989b42283cb50305 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8bb99f50ffe6be4d6ce0f0ff415d6613cb03a98db10219892c55c88aa6a3d881
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]