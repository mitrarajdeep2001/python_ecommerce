#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for postgres..."

# loop until postgres is available
while ! nc -z $POSTGRES_HOST $POSTGRES_PORT; do
  sleep 1
done

echo "PostgreSQL started"

# If no Django project, create one
if [ ! -f manage.py ]; then
  django-admin startproject main .
fi

# Run migrations
python manage.py migrate --noinput

# Create superuser if not exists
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
username = "${DJANGO_SUPERUSER_USERNAME}"
email = "${DJANGO_SUPERUSER_EMAIL}"
password = "${DJANGO_SUPERUSER_PASSWORD}"

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print("Superuser created.")
else:
    print("Superuser already exists.")
EOF

# Start Tailwind in the background
python manage.py tailwind start &

# Start Django dev server
exec python manage.py runserver 0.0.0.0:8000
