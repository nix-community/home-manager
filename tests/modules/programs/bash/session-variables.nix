{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bash = {
      enable = true;

      sessionVariables = {
        V1 = "v1";
        V2 = "v2-${config.programs.bash.sessionVariables.V1}";
      };
    };

    nmt.script = ''
      assertFileExists home-files/.profile
      assertFileContent \
        home-files/.profile \
        ${./session-variables-expected.txt}
    '';
  };
}
