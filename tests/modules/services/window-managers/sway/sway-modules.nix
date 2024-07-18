{ config, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config = {
      menu = "${pkgs.dmenu}/bin/dmenu_run";

      input = { "*" = { xkb_variant = "dvorak"; }; };
      output = { "HDMI-A-2" = { bg = "~/path/to/background.png fill"; }; };
      seat = { "*" = { hide_cursor = "when-typing enable"; }; };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-modules.conf}
  '';
}
