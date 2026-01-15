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


    systemd = {
      enable = mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`niri-session.target` on
          niri startup. This links to {file}`graphical-session.target`}.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching the target, including
          - `DISPLAY`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
          - `NIXOS_OZONE_WL`
          - `XCURSOR_THEME`
          - `XCURSOR_SIZE`
        '';
      };

      variables = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
        example = [ "-all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "systemctl --user stop niri-session.target"
          "systemctl --user start niri-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };
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
