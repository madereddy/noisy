FROM cgr.dev/chainguard/python:latest-dev@sha256:8822335948a77f0ad8025c9f83f82fb4b1e266b3d48d3991d20c5f2b2248af55 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:26af703291a0edd92560df0ddfaaa6deb07be1885131991edd195d9d6f5e1885
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]