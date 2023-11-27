FROM cgr.dev/chainguard/python:latest-dev@sha256:76d61d875c93a92a6521780dcb7867120b578d7e5aa879996203409442eb7338 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3bda94c431d4937258559b84527decfc9e040911e360d7c770ee05528a038ed7
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]