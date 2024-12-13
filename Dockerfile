FROM cgr.dev/chainguard/python:latest-dev@sha256:912ce75048fac19785891f3ab53f4ccd3ac714d920aaf6e5f8919bb25e109126 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b69271bb5c3f06f5afa4c40a77867784e907408ab991e4d6e907f5aa796b87b8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]