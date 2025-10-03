FROM cgr.dev/chainguard/python:latest-dev@sha256:2989250ea6117fe86abfa8edc1102b0eafc18c8bedaed3f5e8751fc519b2d7fe AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ba57d249a2ecf076795604b522e2a2945031bb70607e45e09e410e9b8207b715
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
