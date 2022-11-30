{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.haskell.ghcup;
in {
  options.programs.haskell.ghcup = {
    enable = mkEnableOption "ghcup, the Haskell toolchain installer";
    package = mkPackageOption pkgs "ghcup" { };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
