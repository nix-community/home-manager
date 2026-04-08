{ pkgs }:
let
  statixFormatter = pkgs.writeShellApplication {
    name = "treefmt-statix";
    text = ''
      set -eu

      for file in "$@"; do
        ${pkgs.statix}/bin/statix fix --config ${../statix.toml} -- "$file"
      done
    '';
  };
in
pkgs.treefmt.withConfig {
  runtimeInputs = with pkgs; [
    nixfmt
    statixFormatter
    deadnix
    keep-sorted
    nixf-diagnose
  ];
  settings = pkgs.lib.importTOML ../treefmt.toml;
}
