# Stage 1: Build React frontend
FROM node:18 AS frontend
WORKDIR /app
COPY frontend/ /app/
RUN npm install
RUN npm run build

# Stage 2: Django app
FROM python:3.12

RUN echo "deb https://deb.debian.org/debian unstable main contrib" >> /etc/apt/sources.list && \
    echo "Package: *" >> /etc/apt/preferences && \
    echo "Pin: release a=unstable" >> /etc/apt/preferences && \
    echo "Pin-Priority: 10" >> /etc/apt/preferences

RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl g++ python3-dev && \
    apt-get install --yes -t unstable gdal-bin libgdal-dev && \
    rm -rf /var/lib/apt/lists/*

ENV GDAL_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/libgdal.so
ENV GDAL_DATA=/usr/share/gdal
ENV PATH=/root/.local/bin:$PATH

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH=/app

WORKDIR /app

COPY backend/pyproject.toml /app/
COPY backend/poetry.lock /app/

RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-root

# Copy backend files
COPY backend/ /app/

# Copy React static build
COPY --from=frontend /app/build /app/frontend/build

CMD ["sh", "-c", "python manage.py collectstatic --noinput && gunicorn labs_project.wsgi:application --bind 0.0.0.0:8000"]
