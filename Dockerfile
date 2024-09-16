FROM cgr.dev/chainguard/python:latest-dev@sha256:768532cf7e27edda12636e4b534ce22c5f64c8deae85bdc576d7578c4eced815 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1459ed299b45f06067c11c02d27d144c84bf9029b35595a0d92930a1ce36ad8b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]