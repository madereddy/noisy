FROM cgr.dev/chainguard/python:latest-dev@sha256:7e1c467fe1ba38a2835816c1c4161f8c4fe255823aae00d1363090cacacda8f5 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:944f0e85bf1ba7b20d2755b9be05b5cb155aa8624c11cfae2126786428343202
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]