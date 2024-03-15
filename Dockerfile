FROM cgr.dev/chainguard/python:latest-dev@sha256:909845588bdab160309776be62a677d1cc53211ce04dbc317cd75af974e949a0 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0492ec3eb9f43757c3a5d42198ea85fb61757700cd98436577a1924ec9d11c4e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]