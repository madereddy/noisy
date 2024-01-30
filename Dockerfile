FROM cgr.dev/chainguard/python:latest-dev@sha256:80e9bf37c59c9ac927491f4933e4d5c414028a42a5ba4240f8a5af01136b35df as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3938b12f0756715f6ee7c0a27dd9ef2763bcd2dfff2673c17761eaa3c2cb1b84
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]