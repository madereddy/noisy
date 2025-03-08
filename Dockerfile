FROM cgr.dev/chainguard/python:latest-dev@sha256:697c23f892dddff4b29e229a7cb7c198ba037445d042c5f05a8a3f127e1edce6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e1571a9e6e78d6355371fede729db3050b4611391a31fcf1b3ee24b1920f7656
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
