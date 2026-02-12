# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:b137d8e65a9fbe54ac1d51afcf567ccf1b9728d941c04d9f99fe9aac4006bb53 AS builder
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
FROM cgr.dev/chainguard/python:latest@sha256:4e0071d93c68dc02059f220342a75cec135b252970416cb4e4bfd28024c7e2e1
WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /app/venv /app/venv

# Copy app and config
COPY --from=builder /app /app

# Update PATH to use venv by default
ENV PATH="/app/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT [ "python", "/app/noisy.py" ]
