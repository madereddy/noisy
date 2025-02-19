FROM cgr.dev/chainguard/python:latest-dev@sha256:cd0e098eca23dd3bb9b5f40615b0dcdc88f9aacfcf36752e0a92d1d23f6472c3 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1d131f75c981ff77135f9428abe54584a99b579398dfabba4d85998d0709fb1f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
