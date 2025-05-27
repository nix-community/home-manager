{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.fnott;

  concatStringsSep' = sep: list: lib.concatStringsSep sep (lib.remove "" list);

  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = [ ];

  options = {
    services.fnott = {
      enable = lib.mkEnableOption ''
        fnott, a lightweight Wayland notification daemon for wlroots-based compositors
      '';

      package = lib.mkPackageOption pkgs "fnott" { };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-s" ];
        description = ''
          Extra arguments to use for executing fnott.
        '';
      };

      configFile = mkOption {
        type = types.either types.str types.path;
        default = "${config.xdg.configHome}/fnott/fnott.ini";
        defaultText = "$XDG_CONFIG_HOME/fnott/fnott.ini";
        description = ''
          Path to the configuration file read by fnott.

          Note that environment variables in the path won't be properly expanded.

          The configuration specified under
          {option}`services.fnott.settings` will be generated and
          written to {file}`$XDG_CONFIG_HOME/fnott/fnott.ini`
          regardless of this option. This allows using a mutable configuration file
          generated from the immutable one, useful in scenarios where live reloading is desired.
        '';
      };

      settings = mkOption {
        type = iniFormat.type;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/fnott/fnott.ini`.

          See
          {manpage}`fnott.ini(5)` for a list of available options and <https://codeberg.org/dnkl/fnott/src/branch/master/fnott.ini>
          for an example configuration.
        '';
        example = lib.literalExpression ''
          {
            main = {
              notification-margin = 5;
            };

            low = {
              timeout = 5;
              title-font = "Dina:weight=bold:slant=italic";
              title-color = "ffffff";
            };
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.fnott" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.fnott = {
      Unit = {
        Description = "Fnott notification daemon";
        Documentation = "man:fnott(1)";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = concatStringsSep' " " [
          "${cfg.package}/bin/fnott"
          "-c ${lib.escapeShellArg cfg.configFile}"
          (lib.escapeShellArgs cfg.extraFlags)
        ];
      };
    };

    xdg.dataFile."dbus-1/services/fnott.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.Notifications
      Exec=${cfg.package}/bin/fnott
      SystemdService=fnott.service
    '';

    xdg.configFile."fnott/fnott.ini".source = iniFormat.generate "fnott.ini" cfg.settings;
  };
}
