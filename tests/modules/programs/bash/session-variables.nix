{ config, ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = false;

    sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.programs.bash.sessionVariables.V1}";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.profile
    assertFileContent \
      "$(normalizeStorePaths home-files/.profile)" \
      ${builtins.toFile "session-variables-expected" ''
        . "/nix/store/00000000000000000000000000000000-hm-session-vars.sh/etc/profile.d/hm-session-vars.sh"

        export V1="v1"
        export V2="v2-v1"


      ''}
  '';
}
