FROM cgr.dev/chainguard/python:latest-dev@sha256:bc6dd9d412ba16a0e7bb02db73b4773cf6b33702c60da52fb2a7decca04eb2fa as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:efb835dda221cc69f2730a9f48ada139a505a9ce54c40f1637177d775f3ca5b9
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
