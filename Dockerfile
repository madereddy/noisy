FROM cgr.dev/chainguard/python:latest-dev@sha256:bd1055ef75f6147dec8c8259ce44f3134e8e59baf46edfd41ed19a75b842e545 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b1da912e82db2c234f15b34c90bf00fc959c52d07f9b2787bebdebe844f5f6e2
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
