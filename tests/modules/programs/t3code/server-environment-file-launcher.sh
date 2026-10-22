#!@shell@
set -a
source /run/secrets/t3code || exit 1
set +a
exec /nix/store/00000000000000000000000000000000-t3/bin/t3 serve

