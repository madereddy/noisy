FROM cgr.dev/chainguard/python:latest-dev@sha256:4968705def11dd6a55b24975611b3e52d502faea31711fae6e297c3741c57a99 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:128a83f2371127148a2640eeca299478ee5437f1c27a6d64d9c66ac9dc8d0252
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]