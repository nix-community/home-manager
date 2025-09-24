{ config, ... }:

{
  programs.sh = {
    enable = true;

    sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.programs.sh.sessionVariables.V1}";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.profile
    assertFileContent \
      home-files/.profile \
      ${builtins.toFile "session-variables-expected" ''
        . "/home/hm-user/.nix-profile/etc/profile.d/hm-session-vars.sh"

        export ENV="$HOME/.shinit"

        export V1="v1"
        export V2="v2-v1"


      ''}
  '';
}
