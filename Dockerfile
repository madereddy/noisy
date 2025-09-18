FROM cgr.dev/chainguard/python:latest-dev@sha256:ec56375a3722c298dea9114e40d824e3edb0c764364dbc7408fe7bba7288e520 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bf7ee653965b385aae959163a7c799338a9de7385d60e9879bc7fac099d71c47
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
