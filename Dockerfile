FROM cgr.dev/chainguard/python:latest-dev@sha256:93e36876968078a8a720f51bcc32c56f0cfd13e95c55b2aec587f407b6ee374d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2ada7aa3b53df8980a65429f2a94865ed29b5d454d36ff78bb89b850c73d54ba
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]