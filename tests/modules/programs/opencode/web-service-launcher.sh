#!@shell@

export PATH="/home/hm-user/.nix-profile/bin${PATH:+:$PATH}"
exec /nix/store/00000000000000000000000000000000-opencode-wrapped-/bin/opencode serve --hostname 0.0.0.0 --port 4096 --mdns --cors https://example.com --cors http://localhost:3000 --print-logs --log-level DEBUG

