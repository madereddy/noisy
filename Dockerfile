FROM cgr.dev/chainguard/python:latest-dev@sha256:2ad42bda7fe146e3f717aaa1d8ecd0f178aa5450898d52b33c52ea1714df5aa6 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9c774781fbaf008bbf43eeae6fd3aef61aed210b11033415a0fd635d4c684633
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]