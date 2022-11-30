{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.rust.clippy;
in {
  options.programs.rust.clippy = {
    enable = mkEnableOption "clippy, the Rust linter";
    package =
      mkPackageOption config.programs.rust.toolchainPackages "clippy" { };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
