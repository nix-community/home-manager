{ lib }:

rec {
  # Quote strings, paths, numbers, or derivations for systemd Exec*.
  # JSON quoting preserves argument boundaries and escapes control characters.
  # Double % and $ to prevent specifier and environment expansion.
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

  # Preserve argument boundaries, including empty arguments.
  escapeExecArgs = lib.concatMapStringsSep " " escapeExecArg;
}
