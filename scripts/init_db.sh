#!/usr/bin/env bash

set -x
set -eo pipefail

#Check if a custom user has been set, otherwise default to postgres
DB_USER=${POSTGRES_USER:=postgres}
#check if password, if not password
DB_PASSWORD="${POSTGRES_PASSWORD:=password}"
#check if db name, if not newsletter
DB_NAME="${POSTGRES_DB:=newsletter}"
#Check if port otherwise 5432
DB_PORT="${POSTGRES_PORT:=5432}"

# Launch postgres using docker
if [[ -z "${SKIP_DOCKER}" ]]
then
  docker run \
    --restart always \
    -e POSTGRES_USER=${DB_USER} \
    -e POSTGRES_PASSWORD=${DB_PASSWORD} \
    -e POSTGRES_DB=${DB_NAME} \
    -p "${DB_PORT}":5432 \
    -d postgres \
    postgres -N 1000
fi
# Keep pinging postgres until it's ready
export PGPASSWORD="${DB_PASSWORD}"
until psql -h "localhost" -U "${DB_USER}" -p "${DB_PORT}" -d "postgres" -c "\q"; do
  >&2 echo "Postgres is still unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up and running on port ${DB_PORT}"

export DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
sqlx database create
sqlx migrate run