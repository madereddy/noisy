FROM cgr.dev/chainguard/python:latest-dev@sha256:342d144118b8c8fdb551694a364766f331d218302b1cd491866bc40f3222053c AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cf6f3adc14698f45472da148b2be9336eb746dc8772dfa6084215df0f635f240
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
