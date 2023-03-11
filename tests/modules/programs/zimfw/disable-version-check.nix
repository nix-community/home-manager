{ config, lib, pkgs, ... }:

with lib; {
  config = {
    programs.zsh = {
      enable = true;
      zimfw = {
        enable = true;
        homeDir = toString pkgs.emptyDirectory;
        disableVersionCheck = true;
      };
    };
    test.stubs = {
      zimfw = { };
      zsh = { };
    };
    nmt.script = ''
      assertFileContains home-files/.zshrc \
        "zstyle ':zim' disable-version-check yes"
      assertFileContains home-files/.zshrc \
        'ZIM_CONFIG_FILE="${config.programs.zsh.zimfw.configFile}"'
      assertFileContains home-files/.zshrc \
        'ZIM_HOME="${config.programs.zsh.zimfw.homeDir}"'
    '';
  };
}
