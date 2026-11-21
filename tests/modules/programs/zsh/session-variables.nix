{ config, ... }:

{
  programs.zsh = {
    enable = true;

    sessionVariables = {
      ALT_CONSTANT = "\${ALT_CONSTANT:+fixed}";
      ALT_IDENTITY = "\${ALT_IDENTITY:+$ALT_IDENTITY}";
      BRACED = "\${BRACED}";
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

      Home Manager applies these values once per session today.
      Applying them in each new Zsh process could change them again.

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
  '';
}
