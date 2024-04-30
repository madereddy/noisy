FROM cgr.dev/chainguard/python:latest-dev@sha256:0841b8e5d0f76a964c4a1dbaa09321cd1b186e9d9a2776363e1a50d2b61ec337 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a7c5dbd20f20aaa49cbb5c2b680b027aa66c9e754da8f90d2c9718976e3acc6a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]