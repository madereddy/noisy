FROM cgr.dev/chainguard/python:latest-dev@sha256:00e687a1c506b2559abb287be347893269c03b749ccefcc0ee511b9c7bfbede4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:05c8eec91c19d8f1ba0c552b2844bb0413b3a467acf7adc93d2adc2e7a902d0f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]