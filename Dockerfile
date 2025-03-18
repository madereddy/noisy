FROM cgr.dev/chainguard/python:latest-dev@sha256:69fb65b317048024e5749fcd292a847d207dc0963ca0916be7333e2c513da39a as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:2abc89970a8732fcc8f4a5011705a0e823c12c80f4e00e3d322b7c09145a016d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
