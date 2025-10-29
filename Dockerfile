FROM cgr.dev/chainguard/python:latest-dev@sha256:b766b72cc0d6ca2b80f19083ec13266c613d7013928887ac7551780545d90827 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:aff11fb801109cee35db8f90412c78d6a242f4f105234764d33238553cc5d870
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
