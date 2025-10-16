FROM cgr.dev/chainguard/python:latest-dev@sha256:16c471378edabfaf00c5e54f62e9bc017383ae30320b23e80866ad449772307a AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:df07729a6842572922ea04b17580ce397f141fbfb9f88265972a840f5fbc567e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
