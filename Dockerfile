FROM cgr.dev/chainguard/python:latest-dev@sha256:2bb9421bc83a3f655ab2aa54655a6853771d84ad54c3aed1056fc595157bdc7b AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:50a76a053d4e769ed7bcfdf681042985b1a9c64815dbee44ced740a126378264
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
