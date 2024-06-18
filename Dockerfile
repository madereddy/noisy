FROM cgr.dev/chainguard/python:latest-dev@sha256:bf1e70106bb48aac361539f368d0ca578f699c1e5b7a2c6368c30e5a64a7e956 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6149c997ef1816ef8acb0f5ba91d7e9253d3ed69f47209e57d85169dee583d00
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]