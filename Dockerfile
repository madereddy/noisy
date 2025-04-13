FROM cgr.dev/chainguard/python:latest-dev@sha256:a5c03c959364178609c0f582b25b870e630f99f9bba6ca8f9336dfbd80e37f9b as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:62d8d564561e3f0680f4246677a7b790620f498119657f859dedd0d2348fae0b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
