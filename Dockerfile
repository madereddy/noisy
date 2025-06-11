FROM cgr.dev/chainguard/python:latest-dev@sha256:422994bcdf2ef4258eb4fa5b350faec426c2f3c5bdde3c9181affb33d309ea37 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:17aa8b20c264a7a352f0885324c22bdecb10efc5021f846e9a0fc881970fc0f2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
