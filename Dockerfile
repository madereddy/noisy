FROM cgr.dev/chainguard/python:latest-dev@sha256:92c4d83b4c0ab161ab1acee860fd1bb64502a525b6c156eed558da35140cf0ad as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a90f92ba770d51f7e95c158d6ed1ac74ccc7332f9b42770d45a638fb1ac42844
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]