#!@shell@
export OPENCODE_CONFIG=/home/hm-user/layers/config.json
export OPENCODE_TUI_CONFIG=/home/hm-user/.config/layers/tui.json
export PATH="/home/hm-user/.nix-profile/bin${PATH:+:$PATH}"
exec @opencode@/bin/opencode serve

