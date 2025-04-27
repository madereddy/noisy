FROM cgr.dev/chainguard/python:latest-dev@sha256:52cb1855a4a08ff02a3ef8821c7c5f50ec63f06e0186416d3237facfb4579010 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ef8bb158785da794a20eed32aa25a11283312974a9f772c06bb91e0b91c60f7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
