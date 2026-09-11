{ config, realPkgs, ... }:

{
  home.sessionVariables.COLLIDE = "generic";

  programs.zsh = {
    enable = true;

    sessionVariables = {
      ALT_CONSTANT = "\${ALT_CONSTANT:+fixed}";
      ALT_IDENTITY = "\${ALT_IDENTITY:+$ALT_IDENTITY}";
      BRACED = "\${BRACED}";
      COLLIDE = "zsh";
      DEFAULT = "\${DEFAULT:-fallback}";
      DIRECT = "$DIRECT";
      ESCAPED = "\\$ESCAPED";
      PATH = "$HOME/bin:$PATH";
      V1 = "v1";
      V2 = "v2-${config.programs.zsh.sessionVariables.V1}";
      IS_EMPTY = "";
      IS_NULL = null;
      IS_FALSE = false;
      IS_TRUE = true;
    };
  };

  test.asserts.warnings.expected = [
    ''
      The following programs.zsh.sessionVariables may change when applied again:

        ESCAPED, defined in `${toString ./session-variables.nix}'
        PATH, defined in `${toString ./session-variables.nix}'

      Home Manager reapplies these values after the generated session
      variables change, so self-referential values can change again.

      For search paths, use home.sessionPath,
      home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
      Those options add only the entries that are missing. For other
      variables, assign a complete value without referring to its previous
      contents.

      This check is best-effort and detects only direct parameter references
      such as $NAME, ''${NAME...}, and ''${#NAME}.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.zshenv
    assertFileContent $(normalizeStorePaths home-files/.zshenv) ${./session-variables.zshenv}
    assertFileExists home-files/.zprofile
    assertFileContent $(normalizeStorePaths home-files/.zprofile) ${./session-variables.zprofile}

    env -u __HM_SESS_VARS_SOURCED -u __HM_ZSH_SESS_VARS_SOURCED \
      PATH=/base HOME=/home/hm-user \
      ${realPkgs.zsh}/bin/zsh -f -c '
        export __HM_ZSH_SESS_VARS_SOURCED=1
        . "$1"

        [ "$V1" = v1 ] || { echo "legacy marker kept V1: $V1"; exit 1; }
        [ "$COLLIDE" = zsh ] \
          || { echo "first COLLIDE: $COLLIDE"; exit 1; }
        [ "$PATH" = /home/hm-user/bin:/base ] \
          || { echo "first PATH: $PATH"; exit 1; }
        [ "$__HM_ZSH_SESS_VARS_SOURCED" != 1 ] \
          || { echo "legacy marker survived"; exit 1; }

        firstMarker=$__HM_ZSH_SESS_VARS_SOURCED
        ${realPkgs.zsh}/bin/zsh -f -c "
          . \"\$1\"
          [ \"\$PATH\" = \"\$2\" ] \
            || { echo \"nested PATH: \$PATH\"; exit 1; }
          [ \"\$COLLIDE\" = zsh ] \
            || { echo \"nested COLLIDE: \$COLLIDE\"; exit 1; }
          [ \"\$__HM_ZSH_SESS_VARS_SOURCED\" = \"\$3\" ] \
            || { echo \"nested marker changed\"; exit 1; }
        " child "$1" "$PATH" "$firstMarker"
      ' shell "$TESTED/home-files/.zshenv" \
      || fail "Zsh session variables did not follow the generation token"
  '';
}
