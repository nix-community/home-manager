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
      assertFileExists $home_files/.bash_logout
      assertFileContent \
        $home_files/.bash_logout \
        ${./logout-expected.txt}
    '';
  };
}
