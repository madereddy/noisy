FROM cgr.dev/chainguard/python:latest-dev@sha256:42fdb3929d1c051cf648dec4d9d84518b12a67f08cb8e256cdca96d89fbb49b9 AS builder

WORKDIR /app

# Create virtualenv inside writable directory
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt

# Copy code and config
COPY noisy.py .
COPY config.json .

# -------------------------

FROM cgr.dev/chainguard/python:latest@sha256:6252e33e2d954d5d4188e68c8268545baa5e05d47f62d9bec295e5cc063bd07f
WORKDIR /app

# Copy app + virtualenv from builder
COPY --from=builder /app /app
ENV PATH="/app/venv/bin:$PATH"

# Run the top-level script directly
ENTRYPOINT ["python", "/app/noisy.py", "--config", "/app/config.json"]
