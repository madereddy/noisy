FROM cgr.dev/chainguard/python:latest-dev@sha256:628cdda3c986b81162a8bc06fd3ad1c9213d88bf7c1f16267736b598a4a20520 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8ab7150acbdfc4dc445503a67c7f69af2eeba6a9b476fb669bb5b2163826ac5a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]