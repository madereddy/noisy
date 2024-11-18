FROM cgr.dev/chainguard/python:latest-dev@sha256:e957d47693d3a9cc23ce7438f287d8332301b1adad0312d258529c5e3abfda68 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5de85837816e630c79597cb0934c352469fe5c2b8e7871da583cec3ef9ec4f43
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]