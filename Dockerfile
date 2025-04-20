FROM cgr.dev/chainguard/python:latest-dev@sha256:3af44d72dacd60a3293286cff8dc40351e39aa80d9f7206402d353c35ea5d0df AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:172a288df4aeb380077d5efabdbda0da08766c8b97f9c3270266bbc0bb47c1b0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
