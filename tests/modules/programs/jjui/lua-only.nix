{ lib, pkgs, ... }:

{
  programs.jjui = {
    enable = true;
    configLua = "function setup(config) end";
  };

  nmt.script = ''
    assertFileExists home-files/.config/jjui/config.lua
    assertPathNotExists home-files/.config/jjui/config.toml
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export JJUI_CONFIG_DIR='
  ''
  + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export JJUI_CONFIG_DIR="/home/hm-user/.config/jjui"'
  '';
}
