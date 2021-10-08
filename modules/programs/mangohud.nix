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
          <filename>~/.config/MangoHud/MangoHud.conf</filename>. See
          <link xlink:href="https://github.com/flightlessmango/MangoHud/blob/master/bin/MangoHud.conf"/>
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
          <filename>~/.config/MangoHud/{application_name}.conf</filename>. See
          <link xlink:href="https://github.com/flightlessmango/MangoHud/blob/master/bin/MangoHud.conf"/>
          for the default configuration.
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
      "MangoHud/MangoHud.conf" =
        mkIf (cfg.settings != { }) { text = renderSettings cfg.settings; };
    } // mapAttrs'
      (n: v: nameValuePair "MangoHud/${n}.conf" { text = renderSettings v; })
      cfg.settingsPerApplication;
  };

  meta.maintainers = with maintainers; [ zeratax ];
}
