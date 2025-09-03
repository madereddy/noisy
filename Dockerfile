FROM cgr.dev/chainguard/python:latest-dev@sha256:7e92ce4e2dbe4ee48cacf580464870f2c0c75389865099e9325d6fb136fcdb3d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cf6f3adc14698f45472da148b2be9336eb746dc8772dfa6084215df0f635f240
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
