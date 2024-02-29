FROM cgr.dev/chainguard/python:latest-dev@sha256:3a95ebbec80663509e75b71e3b6586a5b85a911f2a77cc6bcd5d9553c81050b8 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c7c2a5c9dda407966db7b767aca6f06413941176428eb162b5a9499940407786
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]