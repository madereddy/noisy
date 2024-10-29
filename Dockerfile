FROM cgr.dev/chainguard/python:latest-dev@sha256:352d74d1373b540e0dcbdc0b293c2f0d64ef6a0b78ad93a31a85647da287efcc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c227171043105c2778349aac2b90ebfea60a85a95b77f2df716bdf56515a3d48
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]