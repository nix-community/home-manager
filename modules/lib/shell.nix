{ lib }:

rec {
  # Produces a Bourne shell like statement that prepend new values to
  # an possibly existing variable, using sep(ator).
  # Example:
  #   prependToVar ":" "PATH" [ "$HOME/bin" "$HOME/.local/bin" ]
  #   => "$HOME/bin:$HOME/.local/bin:${PATH:+:}\$PATH"
  prependToVar = sep: n: v:
    "${lib.concatStringsSep sep v}\${${n}:+${sep}}\$${n}";

  # Produces a Bourne shell like variable export statement.
  export = n: v: ''export ${n}="${toString v}"'';

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);
}
