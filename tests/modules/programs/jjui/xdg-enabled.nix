{ lib, pkgs, ... }:

{
  programs.jjui = {
    enable = true;
    configLua = "function setup(config) end";
  };

  xdg = {
    enable = true;
    configHome = "/home/hm-user/custom-xdg";
  };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export XDG_CONFIG_HOME="/home/hm-user/custom-xdg"'
    assertFileExists home-files/custom-xdg/jjui/config.lua
    assertPathNotExists home-files/custom-xdg/jjui/config.toml
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export JJUI_CONFIG_DIR='
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export JJUI_CONFIG_DIR="/home/hm-user/custom-xdg/jjui"'
  '';
}
