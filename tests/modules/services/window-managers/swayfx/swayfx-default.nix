{ config, pkgs, ... }:

{
  wayland.windowManager.swayfx = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swayfx@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./swayfx-default.conf}

    assertFileExists home-files/.config/systemd/user/swayfx-session.target
    assertFileContent home-files/.config/systemd/user/swayfx-session.target \
      ${./swayfx-default.target}
  '';
}
