FROM cgr.dev/chainguard/python:latest-dev@sha256:929904ca26eea23e45bb46886d8a68f6e4b360aaad3ac2339c69f772c2c24dcc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:88e5f22ca92f109112de0e341faa855fd17c714baff51273d1986b2a5b4bc73d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]