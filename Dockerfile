FROM cgr.dev/chainguard/python:latest-dev@sha256:422994bcdf2ef4258eb4fa5b350faec426c2f3c5bdde3c9181affb33d309ea37 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f849a6e62a8f2d7d2a0231949fb92a5e70765ad3adb585410a3497b691d77e7b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
