{ lib, ... }:

{
  # Pin the definition location so the warning's file attribution is
  # deterministic under test.
  imports = [
    (lib.setDefaultModuleLocation "/fake/user-config.nix" {
      home.sessionVariables = {
        # Direct self-references in every supported form must warn.
        SELF_BRACED = "\${SELF_BRACED}:/suffix";
        SELF_DEFAULT = "\${SELF_DEFAULT:-fallback}:/suffix";
        # `\\` is a literal backslash, so the following `$` still expands.
        SELF_DOUBLE_ESCAPED = "\\\\$SELF_DOUBLE_ESCAPED:/suffix";

        # None of these are self-references, so none may appear in the warning.
        ESCAPED = "literal \\$ESCAPED";
        OTHER_VAR = "$UNRELATED:/bin";
        SUBSTRING = "$SUBSTRING_LONGER";
        # `$$` is the shell PID; the name after it is literal text.
        PID_PREFIXED = "$$PID_PREFIXED";
      };
    })
    (lib.setDefaultModuleLocation "/fake/other-config.nix" {
      home.sessionVariables = {
        SELF_DOLLAR = "/prefix:$SELF_DOLLAR";
      };
    })
    # Definitions wrapped in standard properties must still be attributed.
    (lib.setDefaultModuleLocation "/fake/wrapped-config.nix" {
      home.sessionVariables = lib.mkIf true (
        lib.mkMerge [
          (lib.mkBefore {
            SELF_WRAPPED = "$SELF_WRAPPED:/wrapped";
          })
        ]
      );
    })
    # A false mkIf branch does not contribute a value, so it must not be
    # attributed even though it mentions an offending name.
    (lib.setDefaultModuleLocation "/fake/disabled-config.nix" {
      home.sessionVariables = lib.mkIf false {
        SELF_DOLLAR = "/disabled:$SELF_DOLLAR";
      };
    })
  ];

  test.asserts.warnings.expected = [
    ''
      The following home.sessionVariables reference themselves:

        SELF_BRACED, defined in `/fake/user-config.nix'
        SELF_DEFAULT, defined in `/fake/user-config.nix'
        SELF_DOLLAR, defined in `/fake/other-config.nix'
        SELF_DOUBLE_ESCAPED, defined in `/fake/user-config.nix'
        SELF_WRAPPED, defined in `/fake/wrapped-config.nix'

      Session variables are re-exported every time the session variables
      file is sourced, so a self-referential value grows with each new
      shell. As documented in the option description, use
      home.sessionPath, home.sessionSearchVariables, or
      home.sessionSearchVariablesAppend to extend search-path style
      variables instead.

      This check is best-effort: only direct references like $NAME,
      ''${NAME}, and ''${NAME:-...} are detected.
    ''
  ];
}
