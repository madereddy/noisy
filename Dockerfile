FROM cgr.dev/chainguard/python:latest-dev@sha256:9065d5fc6cc0359b06cd259db597fb37a39a3406c5f6b06ace0a548bc5129a83 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:4cd9986c4e8c6c5f091a46f38f19b212e0f46a21e8e6e540596f266a123781c2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]