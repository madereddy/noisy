FROM cgr.dev/chainguard/python:latest-dev@sha256:953c61788842a0f2be9bc2e6acf3c56d0c9f48fe01bdb12402d27fab3b0a25cf as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:f910d00bf6accfa0641eb8220a674d0d2927edbe5b0f5c096fe725cb1b905a60
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]