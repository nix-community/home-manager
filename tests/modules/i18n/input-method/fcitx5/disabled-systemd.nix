{
  lib,
  config,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      systemd.enable = false;
    };
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertPathNotExists home-files/.config/systemd/user/fcitx5-daemon.service
  '';
}
