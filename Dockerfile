FROM cgr.dev/chainguard/python:latest-dev@sha256:0f0edc7e39762dbb0d92fb1152621c3215c5d40f290aa09309031dddb5e6102f as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3c4aa998b280d055537c15120335a9eba76b62f4525454518076b6861cfe788d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]