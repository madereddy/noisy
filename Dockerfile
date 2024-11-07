FROM cgr.dev/chainguard/python:latest-dev@sha256:3d576a0d94b05c0da7fba83c8dbf1d909a61a95132d3f65b409b3eb01bf18633 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5de85837816e630c79597cb0934c352469fe5c2b8e7871da583cec3ef9ec4f43
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]