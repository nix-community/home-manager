{ lib }:

rec {
  # Produces a Bourne shell like statement that appends new values to
  # an possibly existing variable, using sep(ator).
  # Example:
  #   appendToVar ":" "PATH" [ "$HOME/bin" "$HOME/.local/bin" ]
  #   => "$PATH\${PATH:+:}$HOME/bin:$HOME/.local/bin"
  appendToVar = sep: n: v:
    "\$${n}\${${n}:+${sep}}${lib.concatStringsSep sep v}";

  # Produces a Bourne shell like variable export statement.
  export = n: v: ''export ${n}="${toString v}"'';

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);
}
