FROM cgr.dev/chainguard/python:latest-dev@sha256:b86f6c494852b9cd7f4fea35d43594e217d5e5c654e8ce30f40bcf57da3c7234 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:eecc25a11ece319b35025e65080b5a7423507a1a429e9a15e3f936af6845b7a4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
