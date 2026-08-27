{ config, lib, ... }:

let
  eval = lib.evalModules {
    modules = [
      {
        options.demo = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
      }
      (lib.setDefaultModuleLocation "/fake/session-vars.nix" {
        demo = {
          ALTERNATE_COLON = "\${ALTERNATE_COLON:+/prefix:$ALTERNATE_COLON}";
          ALTERNATE_NO_COLON = "\${ALTERNATE_NO_COLON+/prefix:$ALTERNATE_NO_COLON}";
          BRACED = "\${BRACED}:/suffix";
          DOUBLE_ESCAPED = "\\\\$DOUBLE_ESCAPED";
          DOLLAR = "$DOLLAR:/suffix";
          LENGTH = "\${#LENGTH}";
          PATTERN = "\${PATTERN#*:}";
          PID_THEN_REFERENCE = "$$$PID_THEN_REFERENCE";

          ALTERNATE_CONSTANT = "\${ALTERNATE_CONSTANT:+/prefix}";
          ALTERNATE_CONSTANT_NO_COLON = "\${ALTERNATE_CONSTANT_NO_COLON+/prefix}";
          ALTERNATE_IDENTITY = "\${ALTERNATE_IDENTITY:+$ALTERNATE_IDENTITY}";
          ALTERNATE_IDENTITY_NO_COLON = "\${ALTERNATE_IDENTITY_NO_COLON+$ALTERNATE_IDENTITY_NO_COLON}";
          BRACED_IDENTITY = "\${BRACED_IDENTITY}";
          DEFAULT = "\${DEFAULT:-$DEFAULT:/fallback}";
          DOLLAR_IDENTITY = "$DOLLAR_IDENTITY";
          ESCAPED = "\\$ESCAPED";
          NESTED_DEFAULT = "\${NESTED_DEFAULT:-\${HOME}/fallback}";
          NESTED_DEFAULT_DEEP = "\${NESTED_DEFAULT_DEEP:-\${HOME:-\${USER}}/fallback}";
          OTHER_NAME = "$UNRELATED";
          PID = "$$PID";
          PID_PAIR = "$$$$PID_PAIR";
          VALUE = 42;
        };
      })
      (lib.setDefaultModuleLocation "/fake/unrelated.nix" { demo.FINE = "/plain/value"; })
    ];
  };

  warnings = config.lib.shell.selfReferenceWarnings {
    option = eval.options.demo;
    optionPath = "demo";
    rationale = "Repeated application is unsafe here.";
  };

  expected = ''
    The following demo may change when applied again:

      ALTERNATE_COLON, defined in `/fake/session-vars.nix'
      ALTERNATE_NO_COLON, defined in `/fake/session-vars.nix'
      BRACED, defined in `/fake/session-vars.nix'
      DOLLAR, defined in `/fake/session-vars.nix'
      DOUBLE_ESCAPED, defined in `/fake/session-vars.nix'
      LENGTH, defined in `/fake/session-vars.nix'
      PATTERN, defined in `/fake/session-vars.nix'
      PID_THEN_REFERENCE, defined in `/fake/session-vars.nix'

    Repeated application is unsafe here.

    For search paths, use home.sessionPath,
    home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
    Those options add only the entries that are missing. For other
    variables, assign a complete value without referring to its previous
    contents.

    This check is best-effort and detects only direct parameter references
    such as $NAME, ''${NAME...}, and ''${#NAME}.
  '';
in
{
  assertions = [
    {
      assertion = warnings == [ expected ];
      message = "self-reference warning did not match the expected output";
    }
  ];

  nmt.script = ''
    echo "self-reference warning checked" >/dev/null
  '';
}
