{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.wayland.windowManager.niri.xwayland-satellite;

  kdl = pkgs.formats.kdl { version = 1; };
in
{
  meta.maintainers = [ lib.maintainers.sodiboo ];

  options.wayland.windowManager.niri.xwayland-satellite = {
    enable = lib.mkEnableOption "xwayland-satellite integration for niri" // {
      default = true;
    };

    package = lib.mkPackageOption pkgs "xwayland-satellite" { };

    rendered = lib.mkOption {
      type = kdl.type.nestedTypes.node;
      visible = false;
      internal = true;
      readOnly = true;

      default =
        let
          node =
            name: args: children:
            kdl.lib.node null name args { } children;

          plain = name: children: node name [ ] children;
          leaf = name: args: node name args [ ];
        in
        plain "xwayland-satellite" [
          (lib.mkIf (!cfg.enable) [ (leaf "off" [ ]) ])
          (lib.mkIf (cfg.enable) [
            (leaf "path" [ (lib.getExe cfg.package) ])
            cfg.extraConfig
          ])
        ];
    };

    extraConfig = lib.mkOption {
      type = kdl.type;
      default = [ ];
      description = ''
        Extra configuration to append to the `xwayland-satellite` section of niri's configuration file, if xwayland-satellite integration is enabled.
      '';
    };
  };
}
