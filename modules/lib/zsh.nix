{ lib }:

rec {
  # Produces a Zsh shell like value
  toZshValue =
    v:
    if builtins.isBool v then
      if v then "true" else "false"
    else if builtins.isString v then
      lib.escapeShellArg v
    else if builtins.isList v then
      let
        shell = import ./shell.nix { inherit lib; };
      in
      "(${shell.formatShellArrayContent (map toString v)})"
    else
      ''"${toString v}"'';

  # Produces a Zsh shell like definition statement
  define = n: v: "${n}=${toZshValue v}";

  # Given an attribute set containing shell variable names and their
  # assignments, this function produces a string containing a definition
  # statement for each set entry.
  defineAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList define vars);

  # Produces a Zsh shell like export statement
  export = n: v: "export ${define n v}";

  # Given an attribute set containing shell variable names and their
  # assignments, this function produces a string containing an export
  # statement for each set entry.
  exportAll =
    vars:
    {
      indent ? "",
    }:
    let
      separator = if indent == "" then "\n" else "\n" + indent;
    in
    lib.concatStringsSep separator (lib.mapAttrsToList export vars);
}
