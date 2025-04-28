FROM cgr.dev/chainguard/python:latest-dev@sha256:c3a9f5e078335d5c29a1ab9c472fb72c5485913442cd50869bcbc039661423ed AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:528fadcfbab064b4ad1e90c30850eb9042c11ff595322024517da095e7d1da4d
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
