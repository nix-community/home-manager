#!/nix/store/00000000000000000000000000000000-bash/bin/bash
trap "@systemd@/bin/systemctl --user stop dwl-session.target" EXIT
/nix/store/00000000000000000000000000000000-dummy/bin/dwl -s /nix/store/00000000000000000000000000000000-dwl-startup "$@"

