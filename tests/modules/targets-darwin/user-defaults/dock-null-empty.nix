{ pkgs, ... }:
{
  config = {
    targets.darwin.defaults."com.apple.dock" = {
      persistent-apps = [ ];
      persistent-others = null;
    };

    nmt.script = ''
      plist=$(grep -oE '/nix/store/[a-z0-9]+-com[.]apple[.]dock[.]plist' "$TESTED/activate")
      test -n "$plist"
      ${pkgs.python3}/bin/python - "$plist" <<'PY'
      import plistlib
      import sys

      with open(sys.argv[1], "rb") as stream:
          plist = plistlib.load(stream)

      assert plist == {"persistent-apps": []}
      PY
    '';
  };
}
