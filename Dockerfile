FROM cgr.dev/chainguard/python:latest-dev@sha256:1a4f456199de0fcfe5dc420b286fb96251bb826b4e8afedab1da33d4d602a421 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:36f63157191eb52f3296e149e009b6e5a989f5fa03a2e307728545e3cc46fcf0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
