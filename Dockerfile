FROM cgr.dev/chainguard/python:latest-dev@sha256:370b677f44814fe8dda63e9bb407af8fbd1fc147176808f0e5576100f67dbf73 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c938906238f844b80d0783f4d8bcb700bf8c644d647f95b2adeddaa15fa63156
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]