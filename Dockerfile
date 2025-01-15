FROM cgr.dev/chainguard/python:latest-dev@sha256:04ef4c6c16d25cfd581eab1dbc20631b60573b2acd7c752e93dce9c6bb662879 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:be8b29da444bc888f920593b21978b70ec49facfe2ffd24a91c8c3c7084100f5
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
