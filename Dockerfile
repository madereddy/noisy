FROM cgr.dev/chainguard/python:latest-dev@sha256:2c8947a0bd8211e7cc560e2a4f38c3d7df67713e3e2635e6afba588b010a2c4a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:912c717c86f983a0029960016262c2443e44b1b50ca59fdc49228a49ab4173f8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]