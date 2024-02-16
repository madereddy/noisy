FROM cgr.dev/chainguard/python:latest-dev@sha256:b2b9527a277a747cb8db0c7d3e7a4041861eeefe8714cf34985e23a908707008 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e0aaf61c35c3fecc5229d56b316ccfcdc9c43ec72d1a6921e6a92aba784f3e17
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]