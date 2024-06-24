FROM cgr.dev/chainguard/python:latest-dev@sha256:c80dcf4e00ad3e0975b9a4d147fc50b94a596cfd3103ebe6c100682f9d20111d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8346471a731ba7a16f85d577179fc36b384b73edec8f323e97c94844881c7244
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]