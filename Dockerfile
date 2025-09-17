FROM cgr.dev/chainguard/python:latest-dev@sha256:12f318dd067c0633a4509a92167e30d70e5d42e2164b0b01c11ab89acb6c611d AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6b343788efca96782bac17a94653f5695730b0431e3e500c7fe28369f3eabda3
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
