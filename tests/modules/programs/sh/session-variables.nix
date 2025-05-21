{ config, ... }:

{
  programs.sh = {
    enable = true;

    sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.programs.sh.sessionVariables.V1}";
      IS_EMPTY = "";
      IS_NULL = null;
      IS_TRUE = true;
      IS_FALSE = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.profile
    assertFileContent \
      "$(normalizeStorePaths home-files/.profile)" \
      ${builtins.toFile "session-variables-expected" ''
        . "/nix/store/00000000000000000000000000000000-hm-session-vars.sh/etc/profile.d/hm-session-vars.sh"

        ENV="$HOME/.shinit"; export ENV

        export IS_EMPTY=""
        export IS_FALSE="false"
        export IS_TRUE="true"
        export V1="v1"
        export V2="v2-v1"


      ''}
  '';
}
