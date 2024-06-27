FROM cgr.dev/chainguard/python:latest-dev@sha256:6e3444c5ce7069cc02cf266ba0acde7ee436edfecc1d6767d69528a12af3dbaf as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9e1f35b5aac96317bb15c2102d80964b9e6151fcae2662094d4871c87d1c3cfd
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]