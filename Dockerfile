FROM cgr.dev/chainguard/python:latest-dev@sha256:49e7ab76920780bcb0c08b11a4f563c9ad53527b67ef9123ec69b03dd3ffbf54 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:46b76efa3162bd30a0caad8f3dc43719610da23cf49fb3ccf11aad634b4b7a47
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]