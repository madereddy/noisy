FROM cgr.dev/chainguard/python:latest-dev@sha256:255af1bad580e902ae0cf634cee6cdb83fbd7047513b11a7595dfc98c8422e5c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bb4f22b100e31fc42451710ac2ccafe198c3d2d5bb17a309033a782f5c8685ea
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
