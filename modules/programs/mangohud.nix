{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.mangohud;

  settingsType = with types;
    (oneOf [ bool int float str path (listOf (oneOf [ int str ])) ]);

  renderOption = option:
    rec {
      int = toString option;
      float = int;
      path = int;
      bool = "0"; # "on/off" opts are disabled with `=0`
      string = option;
      list =
        lib.concatStringsSep "," (lib.lists.forEach option (x: toString x));
    }.${builtins.typeOf option};

  renderLine = k: v:
    (if lib.isBool v && v then k else "${k}=${renderOption v}");
  renderSettings = attrs:
    lib.strings.concatStringsSep "\n"
    (lib.attrsets.mapAttrsToList renderLine attrs) + "\n";

in {
  options = {
    programs.mangohud = {
      enable = lib.mkEnableOption "Mangohud";

      package = lib.mkPackageOption pkgs "mangohud" { };

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
        example = lib.literalExpression ''
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
        example = lib.literalExpression ''
          {
            mpv = {
              no_display = true;
            };
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
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.mangohud" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.sessionVariables = mkIf cfg.enableSessionWide {
      MANGOHUD = 1;
      MANGOHUD_DLSYM = 1;
    };

    xdg.configFile = {
      "MangoHud/MangoHud.conf" =
        mkIf (cfg.settings != { }) { text = renderSettings cfg.settings; };
    } // lib.mapAttrs' (n: v:
      lib.nameValuePair "MangoHud/${n}.conf" { text = renderSettings v; })
      cfg.settingsPerApplication;
  };

  meta.maintainers = with lib.maintainers; [ zeratax ];
}
