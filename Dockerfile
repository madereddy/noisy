FROM cgr.dev/chainguard/python:latest-dev as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.11/site-packages /home/nonroot/.local/lib/python3.11/site-packages

COPY . /

ENTRYPOINT [ "python", "/app/noisy.py" ]
CMD ["--config", "config.json"]