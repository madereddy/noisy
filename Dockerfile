FROM cgr.dev/chainguard/python:latest-dev@sha256:38d707e270b539b46a0bd385d387a38c699856eec465983f176315778588571c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:5f16431f56f330925a9c8f5168b31ca65f603de15b127b376f8532bab11583c0
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]