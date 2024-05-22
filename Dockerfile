FROM cgr.dev/chainguard/python:latest-dev@sha256:fe6862ec302fd71288cba4bc636454fe160859f615d0d207d73dd76128ad6744 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fcabd6b5ea4a1f20a2451791d4c5db3aacb9f5a097275ba2a90722aa9f0cd9bf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]