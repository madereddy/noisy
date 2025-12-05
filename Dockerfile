FROM cgr.dev/chainguard/python:latest-dev@sha256:6c8b993b7f1024b286e15c77d73a6681eb56f766ddb09f3ee0d90f3b5152ba49 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c8982fceef8e20c2c721789823f752517b57fbcbbe4641cf49f69af560a7bc22
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
