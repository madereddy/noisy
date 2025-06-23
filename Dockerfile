FROM cgr.dev/chainguard/python:latest-dev@sha256:37bdd0309604139f4a3e0e32d8308f860d30ff22bf504df98b87e40b70614661 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5e1aa298ad3f50f105b9121b1d3a39bdbe33e17a5a28555a1d12a7c91529fc15
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
