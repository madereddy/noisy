FROM cgr.dev/chainguard/python:latest-dev@sha256:237d873a449fe2fe4859c13f56b170ba739b0f5c0422f4e139499ecf044f415c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:a4c167ce35fdf4b7edb33084709f5d29906e3326e9cf13d1809ec032c847fad6
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]