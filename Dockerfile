FROM cgr.dev/chainguard/python:latest-dev@sha256:78a6c1fee628bb02cd5ff637c7b08fdf441bba768f71a2caa2744cf7f41dc6bd as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2d89e581391c8f5b4d6da7f3e9212f6882fb3f007fd5e245cad787b625b41791
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]