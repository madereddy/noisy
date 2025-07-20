FROM cgr.dev/chainguard/python:latest-dev@sha256:d81646481c00b3fc80301a69fad4478823e2002c2b3fae29f252e933475adc88 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:557411150431db773abad5967a1ec063f35f884828fa4c95c35b9078f3ac50ee
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
