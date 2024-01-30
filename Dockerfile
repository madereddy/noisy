FROM cgr.dev/chainguard/python:latest-dev@sha256:1a8bc4369d7fd3832c05042526f5016d2f9ada8430c2edb7989b42283cb50305 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3938b12f0756715f6ee7c0a27dd9ef2763bcd2dfff2673c17761eaa3c2cb1b84
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]