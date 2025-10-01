FROM cgr.dev/chainguard/python:latest-dev@sha256:22add031f83bd202570e149529c46354d7e89e5a763e40180dd3fbccec5450b8 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a29d5d87b858052d251cff48b7e3338f8369822e97e01764b51377f880407c8d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
