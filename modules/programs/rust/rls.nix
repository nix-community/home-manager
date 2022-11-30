{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.rust.rls;
in {
  options.programs.rust.rls = {
    enable = mkEnableOption "rls, a Rust language server";
    package = mkPackageOption config.programs.rust.toolchainPackages "rls" { };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
