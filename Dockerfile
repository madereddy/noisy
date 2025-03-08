FROM cgr.dev/chainguard/python:latest-dev@sha256:697c23f892dddff4b29e229a7cb7c198ba037445d042c5f05a8a3f127e1edce6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:73d6dc810155cb01bdc69ff9074cb31010b1cc4926ff1cf28ffdac2fc04a2c12
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
