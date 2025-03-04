FROM cgr.dev/chainguard/python:latest-dev@sha256:b8346becf3b40cb9c24384d93cde248644430254e69161738e5317470cc227f9 as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:081843ee8d42694f0b113aa166a2cbf16c543ba9a89cf554b6f7eb5b00e64a72
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /home/nonroot/.local/lib/python3.13/site-packages /home/nonroot/.local/lib/python3.13/site-packages

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
