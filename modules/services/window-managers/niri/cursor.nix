{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.wayland.windowManager.niri.cursor;

  kdl = pkgs.formats.kdl { version = 1; };
in
{
  options.wayland.windowManager.niri.cursor = {

    # defaults from https://github.com/YaLTeR/niri/blob/fefc0bc0a71556eb75352e2b611e50eb5d3bf9c2/niri-config/src/lib.rs#L989-L992
    xcursor-theme = lib.mkOption {
      type = lib.types.str;
      default = "default";
    };
    xcursor-size = lib.mkOption {
      type = lib.types.int;
      default = 24;
    };

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
        plain "cursor" [
          (leaf "xcursor-theme" cfg.xcursor-theme)
          (leaf "xcursor-size" cfg.xcursor-size)
          cfg.extraConfig
        ];
    };

    extraConfig = lib.mkOption {
      type = kdl.type;
      default = [ ];
      description = ''
        Extra configuration to append to the `cursor` section of niri's configuration file.
      '';
    };
  };
}
