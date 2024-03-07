FROM cgr.dev/chainguard/python:latest-dev@sha256:00e687a1c506b2559abb287be347893269c03b749ccefcc0ee511b9c7bfbede4 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:cdfa7a80d8781149d21fd790e1679232e286d5b2d21f54d511214764275d1632
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.12/site-packages /home/nonroot/.local/lib/python3.12/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]