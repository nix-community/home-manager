{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.i3status;

  toStr = val:
    if isString val then ''"${val}"''
    else if isBool val then (if val then "true" else "false")
    else toString val;

  blockToConfig = block: ''
    ${block.type} ${optionalString (block.name != null) ''"${block.name}"''} {
      ${concatStringsSep "\n" (mapAttrsToList (k: v:
        "${k} = ${toStr v}"
      ) block.opts)}
    }
  '';

  configFile = pkgs.writeText "i3status.conf" ''
    ${concatMapStringsSep "\n" (o: ''order += "${o}"'') cfg.order}
    ${concatMapStringsSep "\n" blockToConfig (attrValues cfg.blocks)}
  '';
in {
  options.programs.i3status = {
    enable = mkEnableOption "i3status: Generates status bar to use with i3bar, dzen2 or xmobar.";

    blocks = mkOption {
      description = "Attribute set of defined i3status blocks.";
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          name = mkOption {
            description = "Name of the i3status block.";
            type = types.nullOr types.str;
            default = null;
          };

          type = mkOption {
            description = "Type of the i3status block (by default attribute name).";
            type = types.str;
            default = name;
          };

          opts = mkOption {
            description = "Options for i3status block.";
            type = types.attrs;
            default = {};
          };
        };
      }));

      example = literalExample ''
        {
          general.opts = {
            output_format = "i3bar";
            colors = true;
            interval = 5;
          };

          online = {};

          disk_root = {
            type = "disk";
            name = "/";
            opts.format = "√ %free";
          };

          load.opts.format = "↺ %1min";

          net_rate.opts = {
            interfaces = "ens3,ens4,wlan0,eth0";
            all_interfaces = false;
            si_units = true;
          };
        }
      '';
    };

    order = mkOption {
      description = "Order of i3status blocks.";
      type = types.listOf types.str;
      default = [];
      example = literalExample ''
        [
          (mkOrder 500 "online_status")
          (mkOrder 510 "disk")
          (mkOrder 520 "load")
          (mkOrder 530 "net_rate")
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.i3status ];
    xdg.configFile."i3status/config".source = configFile;
  };
}
