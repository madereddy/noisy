FROM cgr.dev/chainguard/python:latest-dev@sha256:7e92ce4e2dbe4ee48cacf580464870f2c0c75389865099e9325d6fb136fcdb3d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bb606a2afc594b820a217ee76e7f59651922316bc706ab57a96f6ef3a9356634
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
