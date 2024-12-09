{ config, pkgs, ... }:

{
  imports = [ ./fcitx5-stubs.nix ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = [ pkgs.libsForQt5.fcitx5-chinese-addons ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
  '';
}
