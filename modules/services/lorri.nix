{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.lorri;

in {
  meta.maintainers = [ maintainers.gerschtli ];

  options = { services.lorri.enable = mkEnableOption "lorri build daemon"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lorri ];

    systemd.user = {
      services.lorri = {
        Unit = {
          Description = "lorri build daemon";
          Requires = "lorri.socket";
          After = "lorri.socket";
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${pkgs.lorri}/bin/lorri daemon";
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = "read-only";
          Restart = "on-failure";
          Environment = let
            path = with pkgs;
              makeSearchPath "bin" [ nix gitMinimal gnutar gzip ];
          in "PATH=${path}";
        };
      };

      sockets.lorri = {
        Unit = { Description = "Socket for lorri build daemon"; };

        Socket = {
          ListenStream = "%t/lorri/daemon.socket";
          RuntimeDirectory = "lorri";
        };

        Install = { WantedBy = [ "sockets.target" ]; };
      };
    };
  };
}
