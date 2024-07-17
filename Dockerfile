FROM cgr.dev/chainguard/python:latest-dev@sha256:26ed3bc11419b81a1d787e9815024e294adc5c5749ae3d9d944cf93151a93d12 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:26af703291a0edd92560df0ddfaaa6deb07be1885131991edd195d9d6f5e1885
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]