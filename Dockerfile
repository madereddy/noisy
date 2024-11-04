FROM cgr.dev/chainguard/python:latest-dev@sha256:5a34283cae520c1c413cc333a1865a673f4de28cc5b47cb57ac6db20403450d1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fa1f81a0bf96988a576e7f03078b8461d4af90e5585236f8a37e9bafaf81468d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]