FROM cgr.dev/chainguard/python:latest-dev@sha256:0713eb6285652a10246ee465301bf181dc07be6a40425d61f0e9cffd2ebd5deb AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:0a32c558cb68f9743a0492377c84c6d838d52b08cabfca962a17fce3d0ef02aa
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
