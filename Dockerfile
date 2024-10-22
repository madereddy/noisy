FROM cgr.dev/chainguard/python:latest-dev@sha256:a287c47b92f41107e07d825738607d6cdd7a85121e5bffc917303815724d4dfc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6543611b772e428f9506542b16ec58ac085b28ac849b1d40737f9da23ce5f4e1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]