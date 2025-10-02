FROM cgr.dev/chainguard/python:latest-dev@sha256:1e92729545731d940c000951676213a6739dbc6aabbebc842e10783d40062af3 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a29d5d87b858052d251cff48b7e3338f8369822e97e01764b51377f880407c8d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
