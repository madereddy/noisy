FROM cgr.dev/chainguard/python:latest-dev@sha256:cf18a06fb2485556d8ea7f2070e7ca0e6710eeccb69321f8b413ca23677476c1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:912c717c86f983a0029960016262c2443e44b1b50ca59fdc49228a49ab4173f8
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]