{ pkgs, ... }:

{
  programs.npm = {
    enable = true;
    npmrc = "";
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.npmrc
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      "export NPM_CONFIG_USERCONFIG="
  '';
}
