# Additions to the Nix package set and library.

rec {
  # Home Manager's modifications to Nixpkgs.
  overlay = self: super: { lib = import ../lib/stdlib-extended.nix super.lib; };

  # Extends `args.pkgs` if defined or the Nixpkgs in `NIX_PATH`
  # otherwise.
  extendAttrOrDefault = args:
    if builtins.hasAttr "pkgs" args then
      args.pkgs.extend overlay
    else
      import <nixpkgs> { overlays = [ overlay ]; };
}
