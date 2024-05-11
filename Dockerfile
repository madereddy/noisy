FROM cgr.dev/chainguard/python:latest-dev@sha256:237d873a449fe2fe4859c13f56b170ba739b0f5c0422f4e139499ecf044f415c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f910d00bf6accfa0641eb8220a674d0d2927edbe5b0f5c096fe725cb1b905a60
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]