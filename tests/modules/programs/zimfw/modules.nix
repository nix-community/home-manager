{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh = {
      enable = true;
      zimfw = {
        enable = true;
        homeDir = toString pkgs.emptyDirectory;
        zmodules = [ "environment" "git" "input" ];
      };
    };

    test.stubs = {
      zimfw = { };
      zsh = { };
    };

    nmt.script = ''
      assertFileContains home-files/.zshrc \
        'zimfw.zsh init -q'

      assertFileContains home-files/.zimrc \
        'zmodule environment'

      assertFileContains home-files/.zimrc \
        'zmodule git'

      assertFileContains home-files/.zimrc \
        'zmodule input'

      assertFileContains home-files/.zshrc \
        "zstyle ':zim:zmodule' use 'degit'"

      assertFileContains home-files/.zshrc \
        'ZIM_CONFIG_FILE="${config.programs.zsh.zimfw.configFile}"'

      assertFileContains home-files/.zshrc \
        'ZIM_HOME="${config.programs.zsh.zimfw.homeDir}"'
    '';
  };
}
