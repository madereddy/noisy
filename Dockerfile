FROM cgr.dev/chainguard/python:latest-dev@sha256:47915cad1b9d51679fdbd6e29d0a3e07dd37482c5592a76f7257ede966394248 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:afe7b18d32e6f243fa69bdbbb95f568d668c5c42b93e88c19d30ec24f213d31c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
