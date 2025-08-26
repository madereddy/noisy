FROM cgr.dev/chainguard/python:latest-dev@sha256:53a696211852eb96dfa7024efa7bf49154865da50c33a2fe6cd5f02effe4373f AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:40a29d69c56a8908f5367a66275cbc84c9a0532234fdbe945156fdd49ef26fc5
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
