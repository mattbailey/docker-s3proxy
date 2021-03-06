#!/usr/bin/env bash

# Generate whitelist
#WHITELIST=`echo $NGINX_WHITELIST |sed -e 's/,/ /g'`

#for network in $WHITELIST; do
#  echo "allow ${network};" >> /etc/nginx/whitelist.conf
#done

# Generate basic auth file(s)
#echo 'auth_basic "access denied"' > /etc/nginx/auth.conf
#echo 'auth_basic_user_file "/etc/nginx/htpasswd"' >> /etc/nginx/auth.conf

# So that SIGTERM from docker propagates to nginx
trap "echo \"Sending SIGTERM to nginx\"; killall -s SIGTERM nginx" SIGTERM

[[ "$SSL_ONLY" == "true" ]] && \
  sed -ie "s/### SSL_ONLY/if (\$http_x_forwarded_proto != 'https') {rewrite ^ https://\$host\$request_uri? permanent;}" \
  /etc/nginx/nginx.conf

# Fire up nginx, but background it so we can loop through buckets on a timer
nginx -g 'daemon off;' &

while [ 0 ]; do
  echo "Syncing bucket ${AWS_BUCKET}"
  s3cmd -q --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_ACCESS_SECRET_KEY} --no-progress sync s3://${AWS_BUCKET} /bucket 2> /dev/null
  sleep ${INTERVAL}
done
