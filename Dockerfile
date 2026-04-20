FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV UV_SYSTEM_PYTHON=1
ENV HF_HOME=/cache/huggingface
ENV PORT=8000

# Copy dependency files first for layer caching
COPY pyproject.toml uv.lock README.md .python-version ./

# Install dependencies
RUN uv sync --frozen --no-install-project --extra audio

# Copy source code
COPY pocket_tts/ ./pocket_tts/

# Install the project
RUN uv sync --frozen --extra audio

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=15s --start-period=180s --retries=5 \
  CMD curl -f http://localhost:${PORT}/health || exit 1

CMD uv run pocket-tts serve --host 0.0.0.0 --port ${PORT}
