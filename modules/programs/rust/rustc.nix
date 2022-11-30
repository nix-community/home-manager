{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.rust.rustc;
in {
  options.programs.rust.rustc = {
    enable = mkEnableOption "rustc, the Rust compiler";
    package =
      mkPackageOption config.programs.rust.toolchainPackages "rustc" { };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
