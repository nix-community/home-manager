{ config, ... }:
{
  config = {
    services.shikane = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      settings = {
        profile = [
          {
            name = "external-monitor-default";
            output = [
              {
                match = "eDP-1";
                enable = true;
              }
              {
                match = "HDMI-A-1";
                enable = true;
                position = {
                  x = 1920;
                  y = 0;
                };
              }
            ];
          }
          {
            name = "builtin";
            output = [
              {
                match = "eDP-1";
                enable = true;
              }
            ];
          }
        ];
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/shikane.service

      # shikane >=1.1.0 opens config.toml O_RDWR, so HM installs it as a writable
      # file at activation time rather than a read-only home-files symlink.
      assertFileRegex activate 'install -Dm644 /nix/store/[^ ]*-shikane-config'

      # Validate the generated TOML via the store path the activation installs from.
      storePath=$(grep -oE '/nix/store/[^ "]*-shikane-config' "$TESTED/activate" | head -n1)
      if ! cmp -s "$storePath" ${./expected.toml}; then
        fail "shikane config.toml content mismatch:
      $(diff -u "$storePath" ${./expected.toml})"
      fi
    '';
  };
}
