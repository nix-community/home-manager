{ config, pkgs, ... }:

let
  configFile = "home-files/.config/fontconfig/conf.d/10-hm-fonts.conf";
in
{
  fonts.fontconfig.enable = true;

  nmt.script = ''
    assertFileExists ${configFile}
    assertFileContent ${configFile} ${pkgs.writeText "fonts.conf" ''
      <?xml version="1.0" encoding="utf-8"?>
      <fontconfig>
        <cachedir>${config.home.path}/lib/fontconfig/cache</cachedir>
        <description>Add fonts in the Nix user profile</description>
        <dir>${config.home.path}/lib/X11/fonts</dir>
        <dir>${config.home.path}/share/fonts</dir>
        <dir>${config.home.profileDirectory}/lib/X11/fonts</dir>
        <dir>${config.home.profileDirectory}/share/fonts</dir>
        <include ignore_missing="yes">${config.home.path}/etc/fonts/conf.d</include>
        <include ignore_missing="yes">${config.home.path}/etc/fonts/fonts.conf</include>
      </fontconfig>
    ''}
  '';
}
