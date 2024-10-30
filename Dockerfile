FROM cgr.dev/chainguard/python:latest-dev@sha256:352d74d1373b540e0dcbdc0b293c2f0d64ef6a0b78ad93a31a85647da287efcc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:52820d1718fe1263cb8459cf7db1b136bcdf4758ac7f6dff7599d309ebd3eaf8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]