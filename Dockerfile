FROM cgr.dev/chainguard/python:latest-dev@sha256:d9e1598a9f44205d4182c0c54196f7dd6e73ac8cf15cf57ab063ac431b84b5f8 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f488e4481f27bb0e2c312a4e2e0383b7ddbc62dd03290ef7a5e9459fde32447b
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
