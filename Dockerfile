FROM cgr.dev/chainguard/python:latest-dev@sha256:63658227c7ab7721234bf0885232eb11300d2e6693e08f9e78289c8bd9b089a1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:73d190f98ad153222ec562056fd8afd710b0d513d6015672e6198046978942f3
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]