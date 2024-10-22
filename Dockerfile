FROM cgr.dev/chainguard/python:latest-dev@sha256:c7b985fed6442b5cc9b2f97364b7e824c7fd279051dfd9989ebb63c1b3029751 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:6543611b772e428f9506542b16ec58ac085b28ac849b1d40737f9da23ce5f4e1
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]