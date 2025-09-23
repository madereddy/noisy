FROM cgr.dev/chainguard/python:latest-dev@sha256:f0342a9d65009acf1c72146a7a1ea408cf4d65b3adff2dcbe23a736056b115cc AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:afe7b18d32e6f243fa69bdbbb95f568d668c5c42b93e88c19d30ec24f213d31c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
