# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:94105b6bc1761793a0fa73b99c815f1b42e491d9191be46b9cb7c22fba5f1508 AS builder
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
FROM cgr.dev/chainguard/python:latest@sha256:4953695b11dd5ac9a93ebab5f7ebe00f905a672a6c6149ba17f196e41f148a59
WORKDIR /app

# Copy the virtual environment from the builder
COPY --from=builder /app/venv /app/venv

# Copy app and config
COPY --from=builder /app /app

# Update PATH to use venv by default
ENV PATH="/app/venv/bin:$PATH"

# Set entrypoint
ENTRYPOINT [ "python", "/app/noisy.py" ]
