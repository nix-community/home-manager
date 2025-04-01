{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkDefault mkOption types;

  cfg = config.programs.i3status;

  enabledModules = lib.filterAttrs (n: v: v.enable) cfg.modules;

  formatOrder = n: ''order += "${n}"'';

  formatModule = n: v:
    let
      formatLine = n: v:
        let
          formatValue = v:
            if lib.isBool v then
              (if v then "true" else "false")
            else if lib.isString v then
              ''"${v}"''
            else
              toString v;
        in "${n} = ${formatValue v}";
    in ''
      ${n} {
        ${lib.concatStringsSep "\n  " (lib.mapAttrsToList formatLine v)}
      }
    '';

  settingsType = with types; attrsOf (oneOf [ bool int str ]);

  sortAttrNamesByPosition = comparator: set:
    let pos = n: set."${n}".position;
    in lib.sort (a: b: comparator (pos a) (pos b)) (lib.attrNames set);
in {
  meta.maintainers = [ lib.hm.maintainers.justinlovinger ];

  options.programs.i3status = {
    enable = lib.mkEnableOption "i3status";

    enableDefault = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether or not to enable
        the default configuration.
      '';
    };

    general = mkOption {
      type = settingsType;
      default = { };
      description = ''
        Configuration to add to i3status {file}`config`
        `general` section.
        See
        {manpage}`i3status(1)`
        for options.
      '';
      example = literalExpression ''
        {
          colors = true;
          color_good = "#e0e0e0";
          color_degraded = "#d7ae00";
          color_bad = "#f69d6a";
          interval = 1;
        }
      '';
    };

    modules = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Whether or not to enable this module.
            '';
          };
          position = mkOption {
            type = with types; either int float;
            description = ''
              Position of this module in i3status `order`.
            '';
          };
          settings = mkOption {
            type = settingsType;
            default = { };
            description = ''
              Configuration to add to this i3status module.
              See
              {manpage}`i3status(1)`
              for options.
            '';
            example = literalExpression ''
              {
                format = "♪ %volume";
                format_muted = "♪ muted (%volume)";
                device = "pulse:1";
              }
            '';
          };
        };
      });
      default = { };
      description = ''
        Modules to add to i3status {file}`config` file.
        See
        {manpage}`i3status(1)`
        for options.
      '';
      example = literalExpression ''
        {
          "volume master" = {
            position = 1;
            settings = {
              format = "♪ %volume";
              format_muted = "♪ muted (%volume)";
              device = "pulse:1";
            };
          };
          "disk /" = {
            position = 2;
            settings = {
              format = "/ %avail";
            };
          };
        }
      '';
    };

    package = lib.mkPackageOption pkgs "i3status" { nullable = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.i3status = lib.mkIf cfg.enableDefault {
      general = {
        colors = mkDefault true;
        interval = mkDefault 5;
      };

      modules = {
        ipv6 = { position = mkDefault 1; };

        "wireless _first_" = {
          position = mkDefault 2;
          settings = {
            format_up = mkDefault "W: (%quality at %essid) %ip";
            format_down = mkDefault "W: down";
          };
        };

        "ethernet _first_" = {
          position = mkDefault 3;
          settings = {
            format_up = mkDefault "E: %ip (%speed)";
            format_down = mkDefault "E: down";
          };
        };

        "battery all" = {
          position = mkDefault 4;
          settings = { format = mkDefault "%status %percentage %remaining"; };
        };

        "disk /" = {
          position = mkDefault 5;
          settings = { format = mkDefault "%avail"; };
        };

        load = {
          position = mkDefault 6;
          settings = { format = mkDefault "%1min"; };
        };

        memory = {
          position = mkDefault 7;
          settings = {
            format = mkDefault "%used | %available";
            threshold_degraded = mkDefault "1G";
            format_degraded = mkDefault "MEMORY < %available";
          };
        };

        "tztime local" = {
          position = mkDefault 8;
          settings = { format = mkDefault "%Y-%m-%d %H:%M:%S"; };
        };
      };
    };

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."i3status/config".text = lib.concatStringsSep "\n" ([ ]
      ++ lib.optional (cfg.general != { }) (formatModule "general" cfg.general)
      ++ map formatOrder (sortAttrNamesByPosition lib.lessThan enabledModules)
      ++ lib.mapAttrsToList formatModule
      (lib.mapAttrs (n: v: v.settings) enabledModules));
  };
}
