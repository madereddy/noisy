FROM cgr.dev/chainguard/python:latest-dev@sha256:8e01369050822ac87b5c2167e2d7a527e9ee9fb014336475591ed64a0cfdc68b AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e8ade02dbbcaadac9115af4250af653f97f64849805c668954bc203ad76748b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
