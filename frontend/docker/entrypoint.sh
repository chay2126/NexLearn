#!/bin/sh
set -eu

: "${PORT:=10000}"
: "${API_UPSTREAM:=nexlearn-api:10000}"

envsubst '${PORT} ${API_UPSTREAM}' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
