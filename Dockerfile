FROM cgr.dev/chainguard/python:latest-dev@sha256:570e7c248854d36acfc47758d0f72a844e26c06207750bb16243a21d86cc53e2 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c2f8ee7598d9d959c475428705477e08e199666b6460692b1f0bcb198c1c0676
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]