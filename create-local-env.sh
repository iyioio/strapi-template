#!/bin/bash
cd "$(dirname "$0")"

PORT=$1
if [ "$PORT" == "" ]; then
    PORT=3306
fi

echo "DATABASE_PORT=$PORT" >> .env
echo "APP_KEYS=$(head -c 64 /dev/urandom | base64)" >> .env
echo "JWT_SECRET=$(head -c 64 /dev/urandom | base64)" >> .env
echo "API_TOKEN_SALT=$(head -c 64 /dev/urandom | base64)" >> .env
