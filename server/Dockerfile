FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SAYAD_DB=/data/sayad.db \
    OLD_APP_DIR=/data/old_app

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN useradd --system --uid 1000 sayad && mkdir -p /data/old_app && chown -R sayad /data
USER sayad

# Database and files to import live in this volume.
VOLUME ["/data"]
EXPOSE 8100

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8100/health', timeout=4)"

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8100", "--proxy-headers", "--forwarded-allow-ips", "*"]
