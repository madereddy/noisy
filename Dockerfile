FROM cgr.dev/chainguard/python:latest-dev@sha256:bc65ad3ba2a7afbe44ba950d32d05828af43e0378d30b7ce27826306580d74ec as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c949df891e5463d357b4d8779aa5bf052e8f53cfe7479c95b2ca4ea3b6156634
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]