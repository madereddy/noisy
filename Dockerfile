FROM cgr.dev/chainguard/python:latest-dev@sha256:6f058193d385d8284d2eef6d256435662b80e365292e35ce2621e1a632055db7 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c949df891e5463d357b4d8779aa5bf052e8f53cfe7479c95b2ca4ea3b6156634
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]