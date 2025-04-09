FROM cgr.dev/chainguard/python:latest-dev@sha256:9a07910eabb5768e1254737380b0053a304cb7dd5143938129a7318bc244c143 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:9ae85bc17424cbf379920683c7d8db82612bf78521372bc81b26d8a5a89418aa
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
