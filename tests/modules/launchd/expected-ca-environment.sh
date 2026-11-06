if [ "${NIX_SSL_CERT_FILE+x}" != x ] && [ "${SSL_CERT_FILE+x}" != x ]; then
  export NIX_SSL_CERT_FILE='/certs/company'\''s $bundle.pem'
fi
exec "$@"
