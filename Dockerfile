FROM cgr.dev/chainguard/python:latest-dev@sha256:cf09a89b435b8b9776022c04fc2a05eeed17a8b3ede1f5810412f5229126c08c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:df96b5d06ab0085e81169cd998ef6580da47c51ed69d0780bcd0abc8c7bde154
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]