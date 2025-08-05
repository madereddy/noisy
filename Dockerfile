FROM cgr.dev/chainguard/python:latest-dev@sha256:51693823bf4fd7bcbf56fee2c9d100b263503258019f723288f796f1fdb5947f AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e9c360bf22db15b87f7c41ec123564ac044a167e9feb9ebce67c562f07bb007
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
