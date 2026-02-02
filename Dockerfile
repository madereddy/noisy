# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:d864099fc2fa5729ef12af94aa74dcb32a56b68469863cc0eba8f06533928673 AS builder
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
FROM cgr.dev/chainguard/python:latest@sha256:215e0f214dc7f761932129115eb7d0dc17a3045e4eab4ff4a562334df5d2b709
WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /app/venv /app/venv

# Copy app and config
COPY --from=builder /app /app

# Update PATH to use venv by default
ENV PATH="/app/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT [ "python", "/app/noisy.py" ]
