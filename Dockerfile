FROM cgr.dev/chainguard/python:latest-dev@sha256:202e5d108c3a4aa7ae67171e1d52a03fe8e8cc14264c97cd424c87695d494a86 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:46b76efa3162bd30a0caad8f3dc43719610da23cf49fb3ccf11aad634b4b7a47
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]