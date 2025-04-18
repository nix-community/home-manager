# Confirm that both Firefox and Thunderbird can be configured at the same time.
{
  config,
  lib,
  pkgs,
  ...
}:
lib.recursiveUpdate (import ./thunderbird.nix { inherit config lib pkgs; }) {
  programs.firefox = {
    enable = true;
    package = null;
  };
}
