FROM cgr.dev/chainguard/python:latest-dev@sha256:35c127daed730a69943fc7ba4d136d6c22b878c4eef190d1d8c8720a72ff3ce0 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:e0aaf61c35c3fecc5229d56b316ccfcdc9c43ec72d1a6921e6a92aba784f3e17
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]