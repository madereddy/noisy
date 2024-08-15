FROM cgr.dev/chainguard/python:latest-dev@sha256:db08a948d1416730c8d5602f1f31af120a72ff629cc06cf17058aeed6e1be4f1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f60f5740fefb47ac3120e2f752819b16947ce9085ef30ed49e3a71bb272cd0b7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]