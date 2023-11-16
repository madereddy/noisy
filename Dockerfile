FROM cgr.dev/chainguard/python:latest-dev@sha256:5fd4b2abcc318414952737239676e28f4f3e85636708120aafebd76ee367536d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:dee884d400b9d3b3fcc4b6f463652314ecaa6ef3d1d593bad8be400526e208f3
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]