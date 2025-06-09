FROM cgr.dev/chainguard/python:latest-dev@sha256:105ab40fb09c89f1794a09e3a97dd53f56837f5ae2c59278841c3956c2ebfd38 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5aa7ba42455f6367df5120bf1225add6310cbee6f112a474a80b971ea26a6928
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
