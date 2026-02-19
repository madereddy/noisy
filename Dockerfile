# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:4266f833dc9460c954d4ccdb99781c44949296d6339cf58788df6efc8299b433 AS builder
WORKDIR /app

# Upgrade pip and install virtualenv
RUN python -m pip install --no-cache-dir --upgrade pip setuptools wheel virtualenv

# Copy requirements and install into a venv inside /app
COPY requirements.txt .

# Create virtualenv inside /app/venv (writable path)
RUN python -m virtualenv /app/venv \
    && /app/venv/bin/pip install --prefer-binary -r requirements.txt

# Copy the app and config
COPY . .

# -------------------------
# Final runtime stage
# -------------------------
FROM cgr.dev/chainguard/python:latest@sha256:965525598ca081814d9235c7c7fd712d819f9d4d00cfe57ef9a1186320f44ded
WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /app/venv /app/venv

# Copy app and config
COPY --from=builder /app /app

# Update PATH to use venv by default
ENV PATH="/app/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT [ "python", "/app/noisy.py" ]
