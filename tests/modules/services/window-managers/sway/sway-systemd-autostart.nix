{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";

    systemd.xdgAutostart = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/sway-session.target
    assertFileContent home-files/.config/systemd/user/sway-session.target \
      ${./sway-systemd-autostart.target}
  '';
}
