FROM cgr.dev/chainguard/python:latest-dev@sha256:352705eb5ceda0b78a857c76f533a0b285c8273600c44862929d46fb0222c042 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:46b76efa3162bd30a0caad8f3dc43719610da23cf49fb3ccf11aad634b4b7a47
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]