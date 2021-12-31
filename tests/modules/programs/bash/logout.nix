{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash = {
      enable = true;

      logoutExtra = ''
        clear-console
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.bash_logout
      assertFileContent \
        home-files/.bash_logout \
        ${
          builtins.toFile "logout-expected" ''
            clear-console
          ''
        }
    '';
  };
}
