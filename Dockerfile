FROM cgr.dev/chainguard/python:latest-dev@sha256:af9d618ad0994f19fd93fd9d0096a91c783a2b97883c6add72c89cf81555e048 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3559f62cb6e38925fb97b9479612522abb4522c95b80e65e7f50e9e4a67cc0d9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]