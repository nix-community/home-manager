#!@shell@
set -a
source /run/secrets/t3code || exit 1
set +a
exec @t3code@/bin/t3 serve

