{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption;

  cfg = config.services.grobi;
  jsonFormat = pkgs.formats.json { };
in
{
  imports =
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "services" "grobi" ]
      [ "services" "grobi" "settings" ]
      { preserveOrder = true; }
      [
        "executeAfter"
        "rules"
      ];

  meta.maintainers = [ lib.maintainers.mbrgm ];

  options = {
    services.grobi = {
      enable = lib.mkEnableOption "the grobi display setup daemon";

      package = lib.mkPackageOption pkgs "grobi" { };

      settings = mkOption {
        type = lib.types.submodule {
          freeformType = jsonFormat.type;
          config = {
            execute_after = lib.mkOptionDefault [ ];
            rules = lib.mkOptionDefault [ ];
          };
        };
        default = { };
        example = lib.literalExpression ''
          {
            execute_after = [ "setxkbmap dvorak" ];
            on_failure = [ "notify-send 'Grobi failed'" ];
            rules = [
              {
                name = "Home";
                outputs_connected = [ "DP-2" ];
                configure_single = "DP-2";
                primary = "DP-2";
                atomic = true;
                execute_after = [
                  "''${lib.getExe pkgs.xrandr} --dpi 96"
                  "''${pkgs.xmonad-with-packages}/bin/xmonad --restart"
                ];
              }
            ];
          }
        '';
        description = ''
          Configuration written to {file}`$XDG_CONFIG_HOME/grobi.conf`.
          The `rules` list is evaluated from top to bottom, and processing
          stops after the first matching rule.

          See <https://github.com/fd0/grobi/blob/master/doc/grobi.conf> for
          available settings.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.grobi" pkgs lib.platforms.linux)
    ];

    systemd.user.services.grobi = {
      Unit = {
        Description = "grobi display auto config daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} watch -v";
        Restart = "always";
        RestartSec = "2s";
        Environment = [ "PATH=${pkgs.xrandr}/bin:${pkgs.bash}/bin" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xdg.configFile."grobi.conf".source = jsonFormat.generate "grobi.conf" cfg.settings;
  };
}
