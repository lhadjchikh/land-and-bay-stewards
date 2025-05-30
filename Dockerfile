# Stage 1: Python base with GDAL dependencies
# This stage contains all the heavy dependencies that rarely change
FROM python:3.12 AS python-base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH=/root/.local/bin:$PATH

# Configure apt sources for GDAL
RUN echo "deb https://deb.debian.org/debian unstable main contrib" >> /etc/apt/sources.list && \
    echo "Package: *" >> /etc/apt/preferences && \
    echo "Pin: release a=unstable" >> /etc/apt/preferences && \
    echo "Pin-Priority: 10" >> /etc/apt/preferences

# Install system dependencies including GDAL
# This layer will be cached as long as the package list doesn't change
RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl g++ python3-dev && \
    apt-get install --yes -t unstable gdal-bin libgdal-dev && \
    rm -rf /var/lib/apt/lists/*

# Set GDAL environment variables
ENV GDAL_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libgdal.so \
    GDAL_DATA=/usr/share/gdal

# Install Poetry
RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false

# Stage 2: Python dependencies
# This stage installs Python dependencies which change less frequently than code
FROM python-base AS python-deps

WORKDIR /app

# Copy only dependency files first
COPY backend/pyproject.toml backend/poetry.lock /app/

# Install Python dependencies
# This layer will be cached as long as the dependencies don't change
RUN poetry install --no-root

# Stage 3: Build React frontend
# This stage is separate and can be rebuilt without affecting the Python base
FROM node:18 AS frontend-builder

WORKDIR /app

# Copy package files first to leverage caching
COPY frontend/package.json frontend/package-lock.json /app/

# Install npm dependencies
RUN npm install

# Copy the rest of the frontend code
COPY frontend/ /app/

# Build the frontend
RUN npm run build

# Stage 4: Final image
# This combines the Python base with dependencies and adds application code
FROM python-deps AS final

WORKDIR /app

# Copy backend code (changes frequently)
COPY backend/ /app/

# Copy the built frontend from the frontend stage
COPY --from=frontend-builder /app/build /app/frontend/build

# Command to run the application
CMD ["sh", "-c", "python manage.py collectstatic --noinput && gunicorn labs.core.wsgi:application --bind 0.0.0.0:8000"]
