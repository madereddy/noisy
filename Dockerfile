FROM cgr.dev/chainguard/python:latest-dev@sha256:62015984d59e99faff095c9662b3b891ef40f8331298553418bd78b0b689bf15 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:68aef1701ad7b295f463887b6b48c3b649639de599c6b159912d728f4149c872
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]