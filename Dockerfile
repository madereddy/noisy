FROM cgr.dev/chainguard/python:latest-dev@sha256:d598ae7b80819d68a81aa1550b853162cb930b859022fe7dac0d6f1c819eecdb as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:ebfb1459ba774ae8791cc6b877adcccf28b52bf5136de571312c12539a91837e
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
