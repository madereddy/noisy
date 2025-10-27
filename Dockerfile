FROM cgr.dev/chainguard/python:latest-dev@sha256:4044fc6304eed95fd4525581f9ee6fb9d3f281c97305e933ef4dbfa38d764b92 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:afff737e54552bb2da99773de75cb783f6c8c3285009581592f5b9e6bc4ab1c8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
