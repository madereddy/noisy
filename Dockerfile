FROM cgr.dev/chainguard/python:latest-dev@sha256:d81646481c00b3fc80301a69fad4478823e2002c2b3fae29f252e933475adc88 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4ed46c781e1d87088b9d35828a53a2bb58f65ec9c2ff34e7df2a37e93feac643
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
