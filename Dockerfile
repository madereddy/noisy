FROM cgr.dev/chainguard/python:latest-dev@sha256:191b88a21b0b399a26ccc239601e2bb94c2954e8b14b5ed1760f45bce9abac65 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e0aaf61c35c3fecc5229d56b316ccfcdc9c43ec72d1a6921e6a92aba784f3e17
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]