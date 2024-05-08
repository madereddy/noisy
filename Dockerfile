FROM cgr.dev/chainguard/python:latest-dev@sha256:04217f1db802aa0b5ff8fe582a0975602d96ba0205a07e5902a5d52e10a3d71e as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ba66cab5047b59445be7d413af06d68edf2d7ad26f9f4b2277f37f3229f429c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]