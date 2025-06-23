{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.gnome-keyring;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.gnome-keyring = {
      enable = lib.mkEnableOption "GNOME Keyring";

      components = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "pkcs11"
            "secrets"
            "ssh"
          ]
        );
        default = [ ];
        description = ''
          The GNOME keyring components to start. If empty then the
          default set of components will be started.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.gnome-keyring" pkgs lib.platforms.linux)
      {
        assertion = !config.services.pass-secret-service.enable;
        message = ''
          Only one secrets service per user can be enabled at a time.
          Other services enabled:
          - pass-secret-service
        '';
      }
    ];

    systemd.user.services.gnome-keyring = {
      Unit = {
        Description = "GNOME Keyring";
        PartOf = [ "graphical-session-pre.target" ];
      };

      Service = {
        ExecStart =
          let
            args = lib.concatStringsSep " " (
              [
                "--start"
                "--foreground"
              ]
              ++ lib.optional (cfg.components != [ ]) ("--components=" + lib.concatStringsSep "," cfg.components)
            );
          in
          "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon ${args}";
        Restart = "on-abort";
      };

      Install = {
        WantedBy = [ "graphical-session-pre.target" ];
      };
    };
  };
}
