{ config, pkgs, ... }:

{
  home.enableNixpkgsReleaseCheck = false;
  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
    config = {
      bindswitches = {
        "lid:on" = {
          action = ''exec echo "Lid moved"'';
        };
        "tablet:on" = {
          action = ''exec echo "Lid moved"'';
          reload = true;
          locked = true;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent home-files/.config/sway/config \
      ${./sway-bindswitches.conf}
  '';
}
