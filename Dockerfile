FROM cgr.dev/chainguard/python:latest-dev@sha256:40b76be74c72e7803505dde2c239443ae3aa4946a98d63668e82e61b5bc80464 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c938906238f844b80d0783f4d8bcb700bf8c644d647f95b2adeddaa15fa63156
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]