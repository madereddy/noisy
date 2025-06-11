FROM cgr.dev/chainguard/python:latest-dev@sha256:5d964e2b42d231e78beba4ab87146e7f10b4d93f5c1e29ac4a1b430decfe954b AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:17aa8b20c264a7a352f0885324c22bdecb10efc5021f846e9a0fc881970fc0f2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
