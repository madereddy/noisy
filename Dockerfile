FROM cgr.dev/chainguard/python:latest-dev@sha256:42fdb3929d1c051cf648dec4d9d84518b12a67f08cb8e256cdca96d89fbb49b9 AS builder
ENV PATH="/app/venv/bin:$PATH"
WORKDIR /app
RUN python -m venv /app/venv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6252e33e2d954d5d4188e68c8268545baa5e05d47f62d9bec295e5cc063bd07f
WORKDIR /app

ENV PATH="/venv/bin:$PATH"
# Make sure you update Python version in path
COPY --from=builder /app ./

COPY --from=builder /app/venv /venv

ENTRYPOINT [ "python", "/app/noisy.py" ]
