FROM cgr.dev/chainguard/python:latest-dev@sha256:0c79e000c414e71638be888bc79d8602b4a724f90c5026f3a3fa6a96a07f5117 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f13535deeebbe11a52fd4ac763aebd6bfeb25a80b2344ccc9f405ac2ca344c35
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]