FROM cgr.dev/chainguard/python:latest-dev@sha256:161d40f62539d692874f2f466d2a83fa5eacd014dab6abdd0e40212facf9a8fe as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:1d131f75c981ff77135f9428abe54584a99b579398dfabba4d85998d0709fb1f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
