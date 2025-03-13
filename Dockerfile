FROM cgr.dev/chainguard/python:latest-dev@sha256:c0937cf4c5ea8fb744f05ff11bd437e8b1078ff73706ca46ac78369b7c5477e4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ac069eca3ddab59f2971d3220e124f3389fb0abefe7eb2624038d1e5e47bbc62
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
