{ lib }:

rec {
  dag = import ./dag.nix { inherit lib; };

  assertions = import ./assertions.nix { inherit lib; };

  booleans = import ./booleans.nix { inherit lib; };
  generators = import ./generators.nix { inherit lib; };
  gvariant = import ./gvariant.nix { inherit lib; };
  maintainers = import ./maintainers.nix;
  strings = import ./strings.nix { inherit lib; };
  types = import ./types.nix { inherit gvariant lib; };

  shell = import ./shell.nix { inherit lib; };
  zsh = import ./zsh.nix { inherit lib; };
}
