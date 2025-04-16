FROM cgr.dev/chainguard/python:latest-dev@sha256:1b66369f2985c906d1713152da2d68f6752dbf46cef97304d00224d8c1e380ff AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:7104953a948fcdfcc1305a4140d65e3be95846b109f1fee9c4f8988e215632bc
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
