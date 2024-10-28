FROM cgr.dev/chainguard/python:latest-dev@sha256:ee4858fcdaa85e411c0c7aaa6aa82f60c51b6fb6bc9b2aa6fb925fb3aa4d6e90 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a3894f8ed4e65e21ed1bb423b054c4564b09c92c13835bcbd37d229d5efc9d7d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]