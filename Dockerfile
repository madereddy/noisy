FROM cgr.dev/chainguard/python:latest-dev@sha256:53dd732ffe3ff43681793c325eda8fa5fa6c6b9ab38590ef10490d88b030c9a0 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:fe4740c2caa7ee0bb8a7da188630a4188b33692ce21d71cf30488dcfd570e4a8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]