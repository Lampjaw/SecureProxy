#!/bin/bash

IN="$RouteMaps"
OUT=/etc/nginx/conf.d/app.conf

if [ -z "$IN" ]
then
    echo "Missing RouteMaps environment variable: ex 'Host1=InternalPort1;Host2=InternalPort2...'"
    exit 1
fi

IFS=';' read -ra ROUTEMAP <<< "$IN"
for route in "${ROUTEMAP[@]}"; do
  ROUTEHOST="${route%=*}"
  LOCALPORT="${route#*=}"

  FULLCHAIN_KEY=/etc/nginx/certs/live/$ROUTEHOST/fullchain.pem
  PRIVATE_KEY=/etc/nginx/certs/live/$ROUTEHOST/privkey.pem

  if [ ! -f "$FULLCHAIN_KEY" ]; then
    echo "$FULLCHAIN_KEY not found!"
    exit 1
  fi

  if [ ! -f "$PRIVATE_KEY" ]; then
    echo "$PRIVATE_KEY not found!"
    exit 1
  fi

  cat >> $OUT <<EOL
server {
  listen 80;
  server_name ${ROUTEHOST};

  location /.well-known/acme-challenge/ {
    root /var/www/letsencrypt;
  }

  location / {
    return 301 https://\$host\$request_uri;
  }

  access_log off;
  log_not_found off;
  error_log  /dev/stdout error;
}

server {
  listen 443 ssl;

  ssl_certificate ${FULLCHAIN_KEY};
  ssl_certificate_key ${PRIVATE_KEY};
  
  client_max_body_size 0;

  server_name ${ROUTEHOST};

  location / {
    proxy_pass http://localhost:${LOCALPORT};

    proxy_set_header Host \$host;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection keep-alive;
    proxy_cache_bypass \$http_upgrade;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;
  }

  access_log off;
  log_not_found off;
  error_log  /dev/stdout error;
}
EOL
done

nginx -g "daemon off;"
