FROM cgr.dev/chainguard/python:latest-dev@sha256:d05e9a6f4a5f55b69e5029e09be3135c82778e790cfbbbe8cf1302be2883e715 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2529543f9cdff43e537d1822f6673a53602d0947f82cd7cd4f4b5d7894ff8788
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
