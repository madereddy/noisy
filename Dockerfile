FROM cgr.dev/chainguard/python:latest-dev@sha256:c0937cf4c5ea8fb744f05ff11bd437e8b1078ff73706ca46ac78369b7c5477e4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:12c034b67f24b85db97913589899a5418438e1d9fbe0dbce8abff966ff2bf62a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
