#!/bin/bash

cd /haproxy

echo $BACKENDS|perl -F',' -lane 'foreach my $x (@F){$x=~s/\:/ /g;print "\tserver $x:80 check"};' > backends.cfg

if [ -n $SSL ]
then
  openssl req -new -x509 -days 365 -nodes \
  -out /etc/ssl/certs/haproxy.pem \
  -keyout /etc/ssl/private/haproxy.pem \
  -subj "/C=CA/ST=BC/L=Vancouver/O=XYZ/CN=*.$HOSTNAME"

  cat /etc/ssl/certs/haproxy.pem /etc/ssl/private/haproxy.pem > /haproxy/haproxy.pem
  cat /haproxy/haproxy.cfg.ssl /haproxy/backends.cfg > /haproxy/haproxy.cfg
else
  cat /haproxy/haproxy.cfg.tcp /haproxy/backends.cfg > /haproxy/haproxy.cfg
fi
  
haproxy -f /haproxy/haproxy.cfg
