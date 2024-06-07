FROM cgr.dev/chainguard/python:latest-dev@sha256:c7afe78f15c543c9936151640ce819e4d6cd2cf0f027ac5749d3cda369079675 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6a7100769a082ca01772e302b6fce08a28ea4225bb73fbf1e00dbc0147f79900
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]