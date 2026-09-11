{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  xsuspender-basic-configuration = ./basic-configuration.nix;
  xsuspender-disabled = ./disabled.nix;
  xsuspender-default-configuration = ./default-configuration.nix;
  xsuspender-whole-tree-force = ./whole-tree-force.nix;
  xsuspender-legacy-defaults = ./legacy-defaults.nix;
  xsuspender-default-rule = ./default-rule.nix;
  xsuspender-rules-only = ./rules-only.nix;
  xsuspender-settings-only = ./settings-only.nix;
}
