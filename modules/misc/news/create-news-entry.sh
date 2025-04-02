#!/usr/bin/env nix-shell
#! nix-shell -I https://github.com/NixOS/nixpkgs/archive/05f0934825c2a0750d4888c4735f9420c906b388.tar.gz -i bash -p coreutils

DATE="$(date --iso-8601=second --universal)"
FILENAME="$(date --date="$DATE" +"%Y-%m-%d_%H-%M-%S").nix"
DIRNAME="$(dirname -- "${BASH_SOURCE[0]}")"

cd "$DIRNAME" || {
  >&2 echo "Failed to change to the script directory: $DIRNAME"
  exit 1
}

cat - << EOF > "$FILENAME"
{
  time = "$DATE";
  condition = true;
  message = ''
    PLACEHOLDER
  '';
}
EOF

echo "Successfully created a news file: $DIRNAME/$FILENAME"
echo "You can open the file above in your text editor and edit now."
