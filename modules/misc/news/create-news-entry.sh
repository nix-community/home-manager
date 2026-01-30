#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/88d3861acdd3d2f0e361767018218e51810df8a1.tar.gz -i bash -p coreutils

DATE="$(date --iso-8601=second --universal)"
YEAR="$(date --date="$DATE" +"%Y")"
MONTH="$(date --date="$DATE" +"%m")"
FILENAME_BASE="$(date --date="$DATE" +"%Y-%m-%d_%H-%M-%S")"
DIRNAME="$(dirname -- "${BASH_SOURCE[0]}")"

# Create year/month directory structure if it doesn't exist
mkdir -p "$DIRNAME/$YEAR/$MONTH"

cd "$DIRNAME" || {
  >&2 echo "Failed to change to the script directory: $DIRNAME"
  exit 1
}

cat - << EOF > "$YEAR/$MONTH/$FILENAME_BASE.nix"
{
  time = "$DATE";
  condition = true;
  message = ''
    PLACEHOLDER
  '';
}
EOF

echo "Successfully created a news file: $DIRNAME/$YEAR/$MONTH/$FILENAME_BASE.nix"
echo "You can open the file above in your text editor and edit now."
