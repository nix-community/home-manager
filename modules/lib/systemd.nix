{ lib }:

rec {
  # Quote a string, path, number, or derivation for a systemd Exec* argument.
  # JSON quoting preserves argument boundaries and escapes control characters.
  # Escape systemd specifiers and environment substitutions as literal text.
  escapeExecArg =
    arg:
    let
      s =
        if lib.isPath arg then
          "${arg}"
        else if lib.isString arg then
          arg
        else if lib.isInt arg || lib.isFloat arg || lib.isDerivation arg then
          toString arg
        else
          throw "escapeExecArg only allows strings, paths, numbers and derivations";
    in
    lib.replaceStrings [ "%" "$" ] [ "%%" "$$" ] (builtins.toJSON s);

  # Quote each argument separately, including empty arguments.
  escapeExecArgs = lib.concatMapStringsSep " " escapeExecArg;
}
