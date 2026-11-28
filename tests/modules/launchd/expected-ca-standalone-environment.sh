if [ "${NIX_SSL_CERT_FILE+x}" != x ] && [ "${SSL_CERT_FILE+x}" != x ]; then
  export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
  if /nix/store/00000000000000000000000000000000-launchd-ca-bundle-missing "$NIX_SSL_CERT_FILE"; then
    export NIX_SSL_CERT_FILE=@nss-cacert@/etc/ssl/certs/ca-bundle.crt
  fi
fi
exec "$@"
