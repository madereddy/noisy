FROM cgr.dev/chainguard/python:latest-dev@sha256:3fbba9a36d0c45d64e3365024f7c2e6196704667998ee2d492422b810bec2049 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cde301cd5f4e494b3ecb1d5b0c8370499482fbefd112b72afe87d4e6f29a0bc1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
