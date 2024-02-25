FROM cgr.dev/chainguard/python:latest-dev@sha256:1926972c570b406c72b958cb1401f037c78b83d24421fda069eab03ce4654987 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8fddee16558b827a5c77acfc4a52940aeec9ea889600cc92f642d6eee11fb7eb
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]