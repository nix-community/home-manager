#!@shell@

export PATH="/home/hm-user/.nix-profile/bin${PATH:+:$PATH}"
exec @opencode@/bin/opencode serve

