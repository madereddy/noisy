FROM cgr.dev/chainguard/python:latest-dev@sha256:9a39654a9ee5c6ed6873ca4d76371f6e15b45543da70fc017a1385aead5d71a6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ae85bc17424cbf379920683c7d8db82612bf78521372bc81b26d8a5a89418aa
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
