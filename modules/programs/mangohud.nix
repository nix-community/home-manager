{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.mangohud;

  settingsType = with types;
    (oneOf [ bool int float str path (listOf (oneOf [ int str ])) ]);

  renderOption = option:
    rec {
      int = toString option;
      float = int;
      path = int;
      bool = "false";
      string = option;
      list = concatStringsSep "," (lists.forEach option (x: toString x));
    }.${builtins.typeOf option};

  renderLine = k: v: (if isBool v && v then k else "${k}=${renderOption v}");
  renderSettings = attrs:
    strings.concatStringsSep "\n" (attrsets.mapAttrsToList renderLine attrs)
    + "\n";

in {
  options = {
    programs.mangohud = {
      enable = mkEnableOption "Mangohud";

      package = mkOption {
        type = types.package;
        default = pkgs.mangohud;
        defaultText = literalExpression "pkgs.mangohud";
        description = "The Mangohud package to install.";
      };

      enableSessionWide = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Sets environment variables so that
          MangoHud is started on any application that supports it.
        '';
      };

      settings = mkOption {
        type = with types; attrsOf settingsType;
        default = { };
        example = literalExpression ''
          {
            output_folder = ~/Documents/mangohud/;
            full = true;
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/MangoHud/MangoHud.conf`. See
          <https://github.com/flightlessmango/MangoHud/blob/master/data/MangoHud.conf>
          for the default configuration.
        '';
      };

      settingsPerApplication = mkOption {
        type = with types; attrsOf (attrsOf settingsType);
        default = { };
        example = literalExpression ''
          {
            mpv = {
              no_display = true;
            }
          }
        '';
        description = ''
          Sets MangoHud settings per application.
          Configuration written to
          {file}`$XDG_CONFIG_HOME/MangoHud/{application_name}.conf`. See
          <https://github.com/flightlessmango/MangoHud/blob/master/data/MangoHud.conf>
          for the default configuration.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          ### Time formatting examples
          # time_format=%H:%M
          # time_format=[ %T %F ]
          # time_format=%X # locally formatted time, because of limited glyph range, missing characters may show as '?' (e.g. Japanese)

          ### Display MangoHud version
          # version

          ### Display the current GPU information
          gpu_stats
          gpu_temp
          gpu_core_clock
          gpu_mem_clock
          gpu_power
          # gpu_text=GPU
          # gpu_load_change
          # gpu_load_value=60,90
          # gpu_load_color=39F900,FDFD09,B22222

          ### Display the current CPU information
          cpu_stats
          cpu_temp
          cpu_power
          # cpu_text=CPU
          cpu_mhz
          # cpu_load_change
          # cpu_load_value=60,90
          # cpu_load_color=39F900,FDFD09,B22222
        '';
        description = ''
          Extra configuration lines to add to `$XDG_CONFIG_HOME/MangoHud/MangoHud.conf`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.mangohud" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.sessionVariables = mkIf cfg.enableSessionWide {
      MANGOHUD = 1;
      MANGOHUD_DLSYM = 1;
    };

    xdg.configFile = {
      "MangoHud/MangoHud.conf" = mkIf (cfg.settings != { }) {
        text = (renderSettings cfg.settings) + cfg.extraConfig;
      };
    } // mapAttrs'
      (n: v: nameValuePair "MangoHud/${n}.conf" { text = renderSettings v; })
      cfg.settingsPerApplication;
  };

  meta.maintainers = with maintainers; [ zeratax ];
}
