FROM cgr.dev/chainguard/python:latest-dev@sha256:29a88e7dfc1f147ccb956e2541452e77818c1789e57a108e87879eba9499d9df AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --user
FROM cgr.dev/chainguard/python:latest@sha256:b14c51dcd50db3f476eba232515c9e343058a546c766873991af1e4726f8dbaf
WORKDIR /app

# Make sure you update Python version in path
COPY --from=builder /app /app

COPY . .

ENTRYPOINT [ "python", "/app/noisy.py", "--config", "/app/config.json"]
