FROM cgr.dev/chainguard/python:latest-dev@sha256:1e7504bdd6ef32989a7014b37ef2e8262c4d74feab017dc1da0a25b7d198e149 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e1aa298ad3f50f105b9121b1d3a39bdbe33e17a5a28555a1d12a7c91529fc15
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
