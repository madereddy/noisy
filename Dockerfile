FROM cgr.dev/chainguard/python:latest-dev@sha256:62015984d59e99faff095c9662b3b891ef40f8331298553418bd78b0b689bf15 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e0aaf61c35c3fecc5229d56b316ccfcdc9c43ec72d1a6921e6a92aba784f3e17
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]