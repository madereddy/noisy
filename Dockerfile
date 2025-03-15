FROM cgr.dev/chainguard/python:latest-dev@sha256:5f52f380c6b545cd3f2144a0903db089c0d49332e81ff2d339dc2f8b8a10d16d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fd728e07eea2a5ea9acef0050720485f2a9738cef52ec8931e18cf94ba12c7e2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
