FROM cgr.dev/chainguard/python:latest-dev@sha256:5727408976bf17a1f034ead1bb6f9c145b392e3ffb4246c7e557680dc345f6ff as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fc921903ce0904ef1a0b4e0b442a94d3de1a361999970517679da3382e7dc7d2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]