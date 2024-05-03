FROM cgr.dev/chainguard/python:latest-dev@sha256:041295387410c312bf49d3638cb44c8f27eb6f2d35367eee24fc8d97557649e1 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:604b94c9ce7ba9af070429f423600e248a7dd0c1d65d08f0392a28a7d859e58c
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]