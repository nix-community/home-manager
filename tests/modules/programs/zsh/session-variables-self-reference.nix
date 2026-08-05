{ lib, ... }:

{
  programs.zsh.enable = true;

  # Pin the definition location so the warning's file attribution is
  # deterministic under test.
  imports = [
    (lib.setDefaultModuleLocation "/fake/user-config.nix" {
      programs.zsh.sessionVariables = {
        # Direct self-references in every supported form must warn.
        ZSH_SELF_BRACED = "\${ZSH_SELF_BRACED}:/suffix";
        ZSH_SELF_DEFAULT = "\${ZSH_SELF_DEFAULT:-fallback}:/suffix";
        ZSH_SELF_DOLLAR = "/prefix:$ZSH_SELF_DOLLAR";
        # `\\` is a literal backslash, so the following `$` still expands.
        ZSH_SELF_DOUBLE_ESCAPED = "\\\\$ZSH_SELF_DOUBLE_ESCAPED:/suffix";

        # None of these are self-references, so none may appear in the warning.
        ZSH_ESCAPED = "literal \\$ZSH_ESCAPED";
        # `$$` is the shell PID; the name after it is literal text.
        ZSH_PID_PREFIXED = "$$ZSH_PID_PREFIXED";
        ZSH_OTHER_VAR = "$UNRELATED:/bin";
        ZSH_SUBSTRING = "$ZSH_SUBSTRING_LONGER";
        ZSH_SKIPPED = null;
      };
    })
  ];

  test.asserts.warnings.expected = [
    ''
      The following programs.zsh.sessionVariables reference themselves:

        ZSH_SELF_BRACED, defined in `/fake/user-config.nix'
        ZSH_SELF_DEFAULT, defined in `/fake/user-config.nix'
        ZSH_SELF_DOLLAR, defined in `/fake/user-config.nix'
        ZSH_SELF_DOUBLE_ESCAPED, defined in `/fake/user-config.nix'

      Zsh session variables are re-applied for every new Zsh process,
      so a self-referential value grows with each nested shell. Use
      home.sessionPath, home.sessionSearchVariables, or
      home.sessionSearchVariablesAppend to extend search-path style
      variables instead.

      This check is best-effort: only direct references like $NAME,
      ''${NAME}, and ''${NAME:-...} are detected.
    ''
  ];
}
