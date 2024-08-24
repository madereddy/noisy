FROM cgr.dev/chainguard/python:latest-dev@sha256:2eeec3f6435453b8743db00bfede38f81e3160772456468e6521a3dffa56c1f4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8e1d8d13a046fbcab6ac1f68a0887d737d96c4355aab8e3d3031671a465ee047
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]