{ config, lib, pkgs, ... }:

{
  imports = [ ./sway-stubs.nix ];

  wayland.windowManager.sway = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@sway@"; };
    checkConfig = false;
    # overriding findutils causes issues
    config.menu = "${pkgs.dmenu}/bin/dmenu_run";
    config.bindkeysToCode = true;
    extraConfigEarly = ''
      import $HOME/.cache/wal/colors-sway
    '';
    extraConfig = ''
      exec_always pkill flashfocus; flasfocus &
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/sway/config
    assertFileContent $(normalizeStorePaths home-files/.config/sway/config) \
      ${./sway-bindkeys-to-code-and-extra-config.conf}
  '';
}
