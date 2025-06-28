FROM cgr.dev/chainguard/python:latest-dev@sha256:6c82297e237072211675dd4edfb4d527d02b6cadac250bb0370bdbccae86b826 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:bb629fd022723f8d5eb990a71f18572d29c8c1630e9f3cbd1577501599d22eef
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
