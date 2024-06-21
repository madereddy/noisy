FROM cgr.dev/chainguard/python:latest-dev@sha256:fd845b48e52dd2925b1f2df375520706319189a88f574df02c284205e4af2754 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:7ae818a3d32ecc4c747637a7c2baba5f6e0ba75b2d0ceb6744c3fb0ca8d208d1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]