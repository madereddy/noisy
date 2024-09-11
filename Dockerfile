FROM cgr.dev/chainguard/python:latest-dev@sha256:4d6f418a5dfad7bb4dd2641b5498d3aa53708073c0e1909fde19cf3568c8aa59 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:df995ee70875bcaa0c702bcb3be270df17fac9cbf1316d26bd0c42b907cb508f
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]