FROM cgr.dev/chainguard/python:latest-dev@sha256:3adc324ec3a261daf0bf4c74f8d2cfa97b472f8af6a740b2e2607bb9275a62ca AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:66418898f7988b578e7fc785768757541b5c3ba78202faf135fda92a81b298a2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
