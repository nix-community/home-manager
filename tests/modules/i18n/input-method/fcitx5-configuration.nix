{
  config,
  lib,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      themes.example = {
        theme = ''
          [Metadata]
          Name=example
          Version=0.1
          Author=home-manager
          Description=Theme for testing
          ScaleWithDPI=True
        '';
      };
      classicUiConfig = "Theme=example";
    };
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/fcitx5-daemon.service
    assertFileExists home-files/.local/share/fcitx5/themes/example/theme.conf
    assertFileExists home-files/.local/share/fcitx5/conf/classicui.conf
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GTK_IM_MODULE'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'QT_IM_MODULE'
  '';
}
