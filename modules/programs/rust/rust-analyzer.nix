{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.rust.rust-analyzer;
in {
  options.programs.rust.rust-analyzer = {
    enable = mkEnableOption "rust-analyzer, a Rust language server";
    package = mkPackageOption pkgs "rust-analyzer" { };
  };
  config.home.packages = mkIf cfg.enable [ cfg.package ];
}
