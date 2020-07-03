{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gnome-keyring;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.gnome-keyring = {
      enable = mkEnableOption "GNOME Keyring";

      components = mkOption {
        type = types.listOf (types.enum [ "pkcs11" "secrets" "ssh" ]);
        default = [ ];
        description = ''
          The GNOME keyring components to start. If empty then the
          default set of components will be started.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
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
        in "${pkgs.gnome3.gnome-keyring}/bin/gnome-keyring-daemon ${args}";
        Restart = "on-abort";
      };

      Install = { WantedBy = [ "graphical-session-pre.target" ]; };
    };
  };
}
