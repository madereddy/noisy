FROM cgr.dev/chainguard/python:latest-dev@sha256:e183cb003066fd5ccc9c5f76140e5d840262720e7653bc5bde07f1c318e8ce8c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e57e10d5d66dffa858fabd4cebdb8a0b5a3d02a40c76e87ec2d13a87de51e521
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
