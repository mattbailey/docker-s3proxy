#!/usr/bin/env bash

# expect comma delim'd buckets
BUCKETS=`echo $AWS_BUCKETS | sed -e 's/,/ /g'`

# Generate whitelist
WHITELIST=`echo $NGINX_WHITELIST |sed -e 's/,/ /g'`

for network in $WHITELIST; do
  echo "allow ${network};" >> /etc/nginx/whitelist.conf
done

# Generate basic auth file(s)
echo 'auth_basic "access denied"' > /etc/nginx/auth.conf
echo 'auth_basic_user_file "/etc/nginx/htpasswd"' >> /etc/nginx/auth.conf

# So that SIGTERM from docker propagates to nginx
trap "echo \"Sending SIGTERM to nginx\"; killall -s SIGTERM nginx" SIGTERM

# Fire up nginx, but background it so we can loop through buckets on a timer
mkdir -p /buckets
nginx -g 'daemon off;' &

while [ 0 ]; do
  for bucket in $BUCKETS; do
    mkdir -p /buckets/${bucket}
    echo "Syncing bucket ${bucket}"
    s3cmd --delete-after-fetch --access_key=${AWS_ACCESS_KEY_ID} --secret_key=${AWS_ACCESS_SECRET_KEY} --no-progress sync s3://${bucket} /buckets/${bucket}
  done
  sleep ${INTERVAL}
done
