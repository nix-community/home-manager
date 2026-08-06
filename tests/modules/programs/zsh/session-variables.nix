{ config, lib, ... }:

{
  # The PATH value self-references, which grows per nested Zsh process now
  # that session variables are re-applied. Keep it to pin the warning, with a
  # stable definition location for the warning's file attribution.
  imports = [
    (lib.setDefaultModuleLocation "/fake/user-config.nix" {
      programs.zsh.sessionVariables.PATH = "$HOME/bin:$PATH";
    })
  ];

  programs.zsh = {
    enable = true;

    sessionVariables = {
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
      The following programs.zsh.sessionVariables reference themselves:

        PATH, defined in `/fake/user-config.nix'

      Zsh session variables are re-applied for every new Zsh process,
      so a self-referential value grows with each nested shell. Use
      home.sessionPath, home.sessionSearchVariables, or
      home.sessionSearchVariablesAppend to extend search-path style
      variables instead.

      This check is best-effort: only direct references like $NAME,
      ''${NAME}, and ''${NAME:-...} are detected.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.zshenv
    assertFileContent $(normalizeStorePaths home-files/.zshenv) ${./session-variables.zshenv}
    assertFileExists home-files/.zprofile
    assertFileContent $(normalizeStorePaths home-files/.zprofile) ${./session-variables.zprofile}
  '';
}
