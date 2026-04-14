# -------------------------
# Builder stage
# -------------------------
FROM cgr.dev/chainguard/python:latest-dev@sha256:7f3a281e0b449e1c083001371ee833ba6451742bb4bfcbbe19d049fe92ed8213 AS builder
WORKDIR /app

RUN python -m venv /app/venv

COPY requirements.txt .
RUN /app/venv/bin/pip install --no-cache-dir --prefer-binary -r requirements.txt

# Strip runtime waste from the venv before copying to the final image:
#   - __pycache__ and .pyc/.pyo files are regenerated on first import anyway
#   - .dist-info dirs are only needed by pip, not at runtime
#   - tests/ dirs inside packages are never executed in production
RUN find /app/venv -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null; \
    find /app/venv -name "*.pyc" -delete; \
    find /app/venv -name "*.pyo" -delete; \
    find /app/venv -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null; \
    find /app/venv -type d -name "tests" -exec rm -rf {} + 2>/dev/null; \
    find /app/venv -type d -name "test" -exec rm -rf {} + 2>/dev/null; \
    true

COPY noisy.py .

# -------------------------
# Final runtime stage
# -------------------------
FROM cgr.dev/chainguard/python:latest@sha256:18974e90873baf1217c62e0daeed36ea873fb577193f7ce4814c051e78c68c03
WORKDIR /app

COPY --from=builder /app/venv /app/venv
COPY --from=builder /app/noisy.py /app/noisy.py

ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["python", "/app/noisy.py"]
