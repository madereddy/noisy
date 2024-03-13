FROM cgr.dev/chainguard/python:latest-dev@sha256:49e7ab76920780bcb0c08b11a4f563c9ad53527b67ef9123ec69b03dd3ffbf54 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:227fc741b1ff222576390c28900831e34f817016aa76292913e50f778083f988
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]