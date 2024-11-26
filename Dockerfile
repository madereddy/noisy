FROM cgr.dev/chainguard/python:latest-dev@sha256:76b93ba9466714276b0407aef4b464e3a9dfd3190f1d68ac0bed9e1bbe9b172d as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:84f5d749d6388e677919fd4bf3d40686e34a62453eb602b2f343b8074a1cbb78
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]