FROM cgr.dev/chainguard/python:latest-dev@sha256:0ba7c37037fc1669dd600e3e5348ab0774fc07e504c714cb14bde02708d3290a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b9328fd1f02d7836c7a75b0423ea9b0098e1cc10f6d3b9398bac5ebb4410f316
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
