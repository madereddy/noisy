FROM cgr.dev/chainguard/python:latest-dev@sha256:0d71896f391021f6ed626b9cf59abf6eced0444b5bedb4d1bd24ba478ed5132d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:081843ee8d42694f0b113aa166a2cbf16c543ba9a89cf554b6f7eb5b00e64a72
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
