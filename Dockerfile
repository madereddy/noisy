FROM cgr.dev/chainguard/python:latest-dev@sha256:083c912c707f1d61b9cc41097bacabfc6136aee979e7b570c479632e9e706b6f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:12c034b67f24b85db97913589899a5418438e1d9fbe0dbce8abff966ff2bf62a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
