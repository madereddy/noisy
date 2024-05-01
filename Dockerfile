FROM cgr.dev/chainguard/python:latest-dev@sha256:0c79e000c414e71638be888bc79d8602b4a724f90c5026f3a3fa6a96a07f5117 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f3c4aadce2bd015ec36a777eface9389cb5cf8a0656bd85d7a9b8ce1cfbfac1e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]