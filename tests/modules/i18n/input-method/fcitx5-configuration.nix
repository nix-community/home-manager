{ config, lib, realPkgs, ... }:

lib.mkIf config.test.enableBig {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GTK_IM_MODULE'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'QT_IM_MODULE'
  '';
}
