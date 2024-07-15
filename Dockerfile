FROM cgr.dev/chainguard/python:latest-dev@sha256:8822335948a77f0ad8025c9f83f82fb4b1e266b3d48d3991d20c5f2b2248af55 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f5e8b018012c8767141cce3d14fd065bcbf20034239bd7f750a3d4cee49ce1d2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]