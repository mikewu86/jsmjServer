#!/bin/bash
set -e
# default behaviour is to launch squid
if [[ -z ${1} ]]; then
	cd /app/src
	./skynet/skynet ./src/$NODETYPE/config.lua
	#envsubst '$$LOGINPORT $$GATEPORT' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/default.conf
	#supervisord -c /etc/supervisord.conf -n
else
  exec "$@"
fi