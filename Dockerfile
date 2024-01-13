FROM cgr.dev/chainguard/python:latest-dev@sha256:7528910118e022cfddfaf5e00b7bf9de4ecbb0bd7095df2f92b4ba158aee90f5 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:8eb266ac46896dd7cf17da76164517fe4eb252b33a12031f202054eac403f8bc
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]