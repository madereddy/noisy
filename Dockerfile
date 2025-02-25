FROM cgr.dev/chainguard/python:latest-dev@sha256:42f8308af6d221f960d490e99b938836990bac22bdeb7b3e06f9cde316f9b1f4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cde301cd5f4e494b3ecb1d5b0c8370499482fbefd112b72afe87d4e6f29a0bc1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
