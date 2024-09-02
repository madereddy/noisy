FROM cgr.dev/chainguard/python:latest-dev@sha256:312dcadccf5bfa7a69dd11bbdb0838a49a9993d72225b69a2de1928d5c5f9735 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c949df891e5463d357b4d8779aa5bf052e8f53cfe7479c95b2ca4ea3b6156634
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]