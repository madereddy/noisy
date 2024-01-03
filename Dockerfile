FROM cgr.dev/chainguard/python:latest-dev@sha256:a97bf22a243e5288cfde047b86c4e5bb12df33e6bf911e3af0fa936fe6e3bbd3 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1bc4d08e3de90c60e8526deb81534dbf3a4b5de9fc46c12a3c3de2284924f914
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]