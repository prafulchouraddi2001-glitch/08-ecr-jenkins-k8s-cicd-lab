FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN useradd --system --uid 10001 appuser

COPY app/ ./app/

EXPOSE 8000

USER 10001

CMD ["python", "app/app.py"]
