FROM cgr.dev/chainguard/python:latest-dev@sha256:73a9ab960db627ed594adac1dece3148c08bcc3e17f2069a86d1b20bf90dbd48 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3b0a6aa280f6e2ef661798a4a6a0e9025ee38a3998b49e546ce37711ab1c91e9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
