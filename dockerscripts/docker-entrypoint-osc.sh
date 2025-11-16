#!/bin/sh
#

# Set default PORT if not specified
PORT=${PORT:-8080}

# Configure nginx with the specified PORT
sed "s/PORT_PLACEHOLDER/$PORT/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Configure MinIO console for subpath
if [ -n "${OSC_HOSTNAME}" ]; then
    export MINIO_BROWSER_REDIRECT_URL="https://${OSC_HOSTNAME}/ui/"
    export MINIO_SERVER_URL="https://${OSC_HOSTNAME}"
else
    export MINIO_BROWSER_REDIRECT_URL="http://localhost:$PORT/ui/"
    export MINIO_SERVER_URL="http://localhost:$PORT"
fi

# Start nginx in background
nginx &

# If command starts with an option, prepend minio.
if [ "${1}" != "minio" ]; then
	if [ -n "${1}" ]; then
		set -- minio "$@"
	fi
fi

docker_switch_user() {
	if [ -n "${MINIO_USERNAME}" ] && [ -n "${MINIO_GROUPNAME}" ]; then
		if [ -n "${MINIO_UID}" ] && [ -n "${MINIO_GID}" ]; then
			chroot --userspec=${MINIO_UID}:${MINIO_GID} / "$@"
		else
			echo "${MINIO_USERNAME}:x:1000:1000:${MINIO_USERNAME}:/:/sbin/nologin" >>/etc/passwd
			echo "${MINIO_GROUPNAME}:x:1000" >>/etc/group
			chroot --userspec=${MINIO_USERNAME}:${MINIO_GROUPNAME} / "$@"
		fi
	else
		exec "$@"
	fi
}

## DEPRECATED and unsupported - switch to user if applicable.
docker_switch_user "$@"