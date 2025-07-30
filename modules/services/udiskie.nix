{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  mergeSets = sets: lib.lists.fold lib.attrsets.recursiveUpdate { } sets;

  yaml = pkgs.formats.yaml { };

  cfg = config.services.udiskie;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  imports = [
    (lib.mkRemovedOptionModule [ "services" "udiskie" "sni" ] ''
      Support for Status Notifier Items is now configured globally through the

        xsession.preferStatusNotifierItems

      option. Please change to use that instead.
    '')
  ];

  options = {
    services.udiskie = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable the udiskie mount daemon.

          Note, if you use NixOS then you must add
          `services.udisks2.enable = true`
          to your system configuration. Otherwise mounting will fail because
          the Udisk2 DBus service is not found.
        '';
      };

      package = lib.mkPackageOption pkgs "udiskie" { };

      settings = mkOption {
        type = yaml.type;
        default = { };
        example = lib.literalExpression ''
          {
            program_options = {
              udisks_version = 2;
              tray = true;
            };
            icon_names.media = [ "media-optical" ];
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/udiskie/config.yml`.

          See <https://github.com/coldfix/udiskie/blob/master/doc/udiskie.8.txt#configuration>
          for the full list of options.
        '';
      };

      automount = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to automatically mount new devices.";
      };

      notify = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to show pop-up notifications.";
      };

      tray = mkOption {
        type = types.enum [
          "always"
          "auto"
          "never"
        ];
        default = "auto";
        description = ''
          Whether to display tray icon.

          The options are

          `always`
          : Always show tray icon.

          `auto`
          : Show tray icon only when there is a device available.

          `never`
          : Never show tray icon.
        '';
      };
    };
  };

  config = lib.mkIf config.services.udiskie.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.udiskie" pkgs lib.platforms.linux)
    ];

    xdg.configFile."udiskie/config.yml".source = yaml.generate "udiskie-config.yml" (mergeSets [
      {
        program_options = {
          automount = cfg.automount;
          tray =
            if cfg.tray == "always" then
              true
            else if cfg.tray == "never" then
              false
            else
              "auto";
          notify = cfg.notify;
        };
      }
      cfg.settings
    ]);

    systemd.user.services.udiskie = {
      Unit = {
        Description = "udiskie mount daemon";
        Requires = lib.optional (cfg.tray != "never") "tray.target";
        After = [ "graphical-session.target" ] ++ lib.optional (cfg.tray != "never") "tray.target";
        PartOf = [ "graphical-session.target" ];
      };

      Service.ExecStart = toString (
        [ (lib.getExe' cfg.package "udiskie") ]
        ++ lib.optional config.xsession.preferStatusNotifierItems "--appindicator"
      );

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
