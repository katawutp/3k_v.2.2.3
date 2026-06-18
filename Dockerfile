FROM python:3.13-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/.venv/bin:$PATH"

# Set work directory
WORKDIR /app

# Install system-level packages
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY pyproject.toml uv.lock ./
RUN pip install --upgrade pip && pip install uv
RUN uv sync --no-dev

# Install Node dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy project files
COPY . .

# Build assets and collect static files
RUN npm run minify && python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Run database migrations and start Daphne
CMD sh -c "python manage.py migrate && daphne -b 0.0.0.0 -p $PORT _core.asgi:application"