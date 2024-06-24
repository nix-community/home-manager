{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gnome-keyring;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.gnome-keyring = {
      enable = mkEnableOption "GNOME Keyring";

      useSecurityWrapper = mkEnableOption ''
        using gnome-keyring-daemon wrapped by NixOS security wrapper
        (i.e. {file}`/run/wrappers/bin/gnome-keyring-daemon`) with
        `CAP_IPC_LOCK` to enhance memory security. This option will
        only work on NixOS with system-wide
        {option}`services.gnome.gnome-keyring.enable` option enabled
      '';

      components = mkOption {
        type = types.listOf (types.enum [ "pkcs11" "secrets" "ssh" "gpg" ]);
        default = [ ];
        description = ''
          The GNOME keyring components to start. If empty then the
          default set of components will be started.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.gnome-keyring" pkgs
        lib.platforms.linux)
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
        ExecStart = let
          args = concatStringsSep " " ([ "--start" "--foreground" ]
            ++ optional (cfg.components != [ ])
            ("--components=" + concatStringsSep "," cfg.components));
          executable = if cfg.useSecurityWrapper then
            "/run/wrappers/bin/gnome-keyring-daemon"
          else
            "${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon";
        in "${executable} ${args}";
        Restart = "on-abort";
      };

      Install = { WantedBy = [ "graphical-session-pre.target" ]; };
    };
  };
}
