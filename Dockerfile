FROM cgr.dev/chainguard/python:latest-dev@sha256:a19acee8f1e6ee27c9ee4e18cbd2388e2d2d31f7b631e1ad20e4f715f87d2322 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:de1dc38837ece938b6afe731a9c86bd197114e404db2df187d81ccd9c1fe3227
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
