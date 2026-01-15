{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkPackageOption
    mkIf
    optional
    ;

  cfg = config.wayland.windowManager.niri;

  configOptions = import ./lib/config.nix;

  configGenerator = import ./lib/generator.nix lib;
in
{
  options.wayland.windowManager.niri = {
    enable = mkEnableOption "niri wayland compositor";

    package = mkPackageOption pkgs "niri" { nullable = true; };

    xwayland = {
      enable = mkEnableOption "enable xwayland" // {
        default = true;
      };
      package = mkPackageOption pkgs "xwayland-satellite" { nullable = true; };
    };

    config = mkOption {
      type = types.submodule configOptions;
      default = { };
    };

    extraConfigPre = mkOption {
      default = "";
      type = types.lines;
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      optional (cfg.package != null) cfg.package
      ++ optional (cfg.xwayland.enable && cfg.xwayland.package != null) pkgs.xwayland;

    xdg.configFile."niri/config.kdl".text =
      cfg.extraConfigPre + (configGenerator cfg.config) + cfg.extraConfig;
  };
}
