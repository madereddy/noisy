FROM cgr.dev/chainguard/python:latest-dev@sha256:00776ae12928af25d95aa070402b7da978004ac0fea9273bade8f52ff1ba0c22 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:d12685b5993e6695ec82995219e03135127581289ffc79c991794dcd454188a1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
