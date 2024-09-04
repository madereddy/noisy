FROM cgr.dev/chainguard/python:latest-dev@sha256:da16a852e53e8f2ad0f7b96812e1598d36635c086e7d3883fbde1f9f249b75b8 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1c605c08b30dc8145d27c3e11964d3bfc237a5f96607e1d4fa338048e617266e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]