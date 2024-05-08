FROM cgr.dev/chainguard/python:latest-dev@sha256:953c61788842a0f2be9bc2e6acf3c56d0c9f48fe01bdb12402d27fab3b0a25cf as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ba66cab5047b59445be7d413af06d68edf2d7ad26f9f4b2277f37f3229f429c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]