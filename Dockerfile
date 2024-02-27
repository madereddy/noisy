FROM cgr.dev/chainguard/python:latest-dev@sha256:1926972c570b406c72b958cb1401f037c78b83d24421fda069eab03ce4654987 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d18bb6ba80da7dc894bbb40c438caf37187a2efbbba8560e691e577d8711e778
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]