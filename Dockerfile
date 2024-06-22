FROM cgr.dev/chainguard/python:latest-dev@sha256:b592bfdccd1c488209b416cd500846c85ae5b4d01a69a33e256161579716bd93 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8346471a731ba7a16f85d577179fc36b384b73edec8f323e97c94844881c7244
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]