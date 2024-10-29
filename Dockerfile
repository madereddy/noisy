FROM cgr.dev/chainguard/python:latest-dev@sha256:f116b439a9a6cb0beebb6828f98f4f7035eb742a3ee304878c7cf92afba7eef0 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:c227171043105c2778349aac2b90ebfea60a85a95b77f2df716bdf56515a3d48
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]