FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/.venv/bin:$PATH"

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./
RUN pip install --upgrade pip && pip install uv
RUN uv sync --no-dev

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

RUN npm run minify && python manage.py collectstatic --noinput

EXPOSE 8000

# Use Gunicorn instead of Daphne for better stability
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "_core.wsgi:application"]
