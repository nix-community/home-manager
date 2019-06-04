{ config, lib, ... }:

with lib;

{
  config = {
    pam.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.pam.sessionVariables.V1}";
    };

    nmt.script = ''
      assertFileExists home-files/.pam_environment
      assertFileContent \
        home-files/.pam_environment \
        ${./session-variables-expected.txt}
    '';
  };
}
