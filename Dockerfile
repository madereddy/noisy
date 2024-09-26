FROM cgr.dev/chainguard/python:latest-dev@sha256:2faac6b5b2a6d56349e35ee4168f7210649eb3fe26ed2bc36c399f1bc81498fc as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:3ede67268f05bae458bcc334155f72968a07ba681c7991df5eba75dfd6f7b94a
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]