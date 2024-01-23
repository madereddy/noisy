FROM cgr.dev/chainguard/python:latest-dev@sha256:5f367a60f8328ca2c744664ffb2d8ee35377b9203f62d397d7d1cf81cb0c8039 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0d2d388c31746f7ad6c8563d32c3929b39a8f2487a666d05a7c8095dfac0b125
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]