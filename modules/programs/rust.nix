{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.rust;
in {
  options.programs.rust.toolchainPackages = mkOption {
    type = types.raw;
    description = "The Rust toolchain package set to use";
    default = pkgs.rust.packages.stable;
    defaultText = literalExpression "pkgs.rust.packages.stable";
    example = literalExpression "pkgs.rust.packages.prebuilt";
  };
}
