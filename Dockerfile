FROM cgr.dev/chainguard/python:latest-dev@sha256:340f284b497cf6e85b49f4a03a9908c6ec2ddb7f646f20949f21d69bea5480f2 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e9c360bf22db15b87f7c41ec123564ac044a167e9feb9ebce67c562f07bb007
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
