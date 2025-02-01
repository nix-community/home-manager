{ config, pkgs, ... }:

{
  imports = [ ./fcitx5-stubs.nix ];

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GTK_IM_MODULE'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'QT_IM_MODULE'
  '';
}
