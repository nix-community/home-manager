{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      zimfw = {
        enable = true;
        homeDir = toString pkgs.emptyDirectory;
        degit = false;
      };
    };

    test.stubs = {
      zimfw = { };
      zsh = { };
    };

    nmt.script = ''
      assertFileNotRegex home-files/.zshrc "zstyle ':zim:zmodule' use 'degit'"

      assertFileContains home-files/.zshrc \
        'ZIM_CONFIG_FILE="${config.programs.zsh.zimfw.configFile}"'

      assertFileContains home-files/.zshrc \
        'ZIM_HOME="${config.programs.zsh.zimfw.homeDir}"'
    '';
  };
}
