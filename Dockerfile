# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:b397f616ddbef7e70cb5f4af8a01ffea05d2ffa28601b04d672e041b1eec3872 AS builder
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
FROM cgr.dev/chainguard/python:latest@sha256:292095443fbb5bb18a7fced80b04f6f330e1873e0be0e21d360f0ecd4dbedcf0
WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /app/venv /app/venv

# Copy app and config
COPY --from=builder /app /app

# Update PATH to use venv by default
ENV PATH="/app/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT [ "python", "/app/noisy.py" ]
