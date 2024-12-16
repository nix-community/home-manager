{ config, lib, ... }:

with lib;

{
  config = {
    home.sessionVariablesFileName = "foobar-session-vars.sh";

    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    nmt.script = ''
      assertPathNotExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists home-path/etc/profile.d/foobar-session-vars.sh \
      assertFileContent \
        home-path/etc/profile.d/foobar-session-vars.sh \
        ${./session-variables-expected.txt}
    '';
  };
}
