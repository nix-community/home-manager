{ pkgs }:
pkgs.treefmt.withConfig {
  runtimeInputs = with pkgs; [
    nixfmt
    deadnix
    keep-sorted
    nixf-diagnose
  ];
  settings = pkgs.lib.importTOML ../treefmt.toml;
}
