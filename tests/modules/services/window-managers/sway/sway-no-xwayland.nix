{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;

    config = null;
    systemd.enable = false;
    xwayland = false;
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
        ${
          pkgs.writeText "expected" ''
            xwayland disable
          ''
        }
  '';
}
