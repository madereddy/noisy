FROM cgr.dev/chainguard/python:latest-dev@sha256:2511845fcd384226ef3eba33dfd9eb594b77d1a050387cd77062c24e5b1be251 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:68a0005cc572e765ea6dfac15d2cf05a6bbe40856210c1cbf0405aa472dbbbad
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]