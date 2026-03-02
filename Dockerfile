# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:90e7427f9fc2ef755002aced581c81b1257870c06a3463bbb9704fcd9387e738 AS builder
WORKDIR /app

# Use stdlib venv instead of the virtualenv package — no extra install needed.
# --no-cache-dir on both pip calls keeps the builder layer lean.
RUN python -m venv /app/venv

COPY requirements.txt .
RUN /app/venv/bin/pip install --no-cache-dir --prefer-binary -r requirements.txt

# Copy only the files needed at runtime — not the whole repo
COPY noisy.py .

# -------------------------
# Final runtime stage
# -------------------------
FROM cgr.dev/chainguard/python:latest@sha256:e47c748a643dc09d98587839d62ae8b76aa2a192af6ec6506fa6a305901b7810
WORKDIR /app

# Copy venv and app file in separate statements so each has its own
# cache layer — changing noisy.py won't invalidate the venv layer.
COPY --from=builder /app/venv /app/venv
COPY --from=builder /app/noisy.py /app/noisy.py

ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["python", "/app/noisy.py"]
