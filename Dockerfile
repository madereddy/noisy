FROM cgr.dev/chainguard/python:latest-dev@sha256:7fc4bfb1754ddd4efffa1fb908a006636cb6a706d299042276ee9b865a96649c as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:02c24c3874435cd6ef510e8231eb461f38c9c1e432d2296513f412b65681d511
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]