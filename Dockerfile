FROM cgr.dev/chainguard/python:latest-dev@sha256:d668d153281dbec86a6a16adbf1706cba57a5f892d7bdf03d4784e07572d558d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b14c51dcd50db3f476eba232515c9e343058a546c766873991af1e4726f8dbaf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
