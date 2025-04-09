FROM cgr.dev/chainguard/python:latest-dev@sha256:9a07910eabb5768e1254737380b0053a304cb7dd5143938129a7318bc244c143 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:eecc25a11ece319b35025e65080b5a7423507a1a429e9a15e3f936af6845b7a4
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
